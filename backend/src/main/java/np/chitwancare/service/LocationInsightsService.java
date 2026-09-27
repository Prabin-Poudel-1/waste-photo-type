package np.chitwancare.service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import np.chitwancare.enums.Role;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/** Read-only, explicit public fields. Existing report access/assignments remain unchanged. */
@Service
public class LocationInsightsService {
    private final NamedParameterJdbcTemplate jdbc;
    private final ReportAccessService access;

    public LocationInsightsService(
            NamedParameterJdbcTemplate jdbc,
            ReportAccessService access) {
        this.jdbc = jdbc;
        this.access = access;
    }

    public record MapReport(
            long id,
            double latitude,
            double longitude,
            String statusGroup,
            String touristSpot,
            Instant createdAt,
            List<String> categories,
            boolean canViewDetails) {}

    public record MapPage(
            List<MapReport> reports,
            boolean truncated) {}

    public record Ranking(
            String name,
            long count) {}

    public record Overview(
            long total,
            long active,
            long submitted,
            long assigned,
            long inProgress,
            long resolved) {}

    public record Insights(
            Overview overview,
            List<Ranking> touristSpots,
            List<Ranking> categories) {}

    private static final String DEPARTMENT_SCOPE =
            " AND EXISTS ("
                    + "SELECT 1 FROM report_assignments a "
                    + "WHERE a.report_id=r.id "
                    + "AND a.active "
                    + "AND a.department_id=:department) ";

    public static String group(String status) {
        return switch (status) {
            case "ASSIGNED", "IN_PROGRESS" ->
                    "HANDLING";
            case "RESOLVED" -> "RESOLVED";
            default -> "ATTENTION";
        };
    }

    @Transactional(readOnly = true)
    public MapPage map(
            double south,
            double west,
            double north,
            double east,
            String filter) {
        if (!Double.isFinite(south)
                || !Double.isFinite(west)
                || !Double.isFinite(north)
                || !Double.isFinite(east)
                || south < -90
                || north > 90
                || west < -180
                || east > 180
                || south >= north
                || west >= east
                || !Set.of(
                        "ALL",
                        "ACTIVE",
                        "RESOLVED")
                .contains(filter)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid map bounds or filter.");
        }

        var user = access.currentUser();
        var parameters =
                new HashMap<String, Object>();

        parameters.put("south", south);
        parameters.put("west", west);
        parameters.put("north", north);
        parameters.put("east", east);

        String scope = "";

        if (user.getRole() == Role.DEPARTMENT) {
            parameters.put(
                    "department",
                    access.departmentId(user));
            scope = DEPARTMENT_SCOPE;
        }

        String status =
                filter.equals("RESOLVED")
                        ? " AND r.current_status='RESOLVED' "
                        : filter.equals("ACTIVE")
                          ? " AND r.current_status NOT IN ('RESOLVED','REJECTED') "
                          : " AND r.current_status<>'REJECTED' ";

        var rows =
                jdbc.query(
                        """
                        SELECT r.id,r.latitude,r.longitude,r.current_status,r.created_at,r.reporter_id,t.name AS spot,
                          ARRAY(SELECT DISTINCT c.name FROM waste_detections d JOIN waste_categories c ON c.id=d.waste_category_id WHERE d.report_id=r.id ORDER BY c.name) AS categories
                        FROM waste_reports r LEFT JOIN tourist_spots t ON t.id=r.tourist_spot_id
                        WHERE r.latitude BETWEEN :south AND :north AND r.longitude BETWEEN :west AND :east
                        """
                                + scope
                                + status
                                + " ORDER BY r.created_at DESC,r.id DESC LIMIT 501",
                        parameters,
                        (result, number) ->
                                new MapReport(
                                        result.getLong("id"),
                                        result.getDouble("latitude"),
                                        result.getDouble("longitude"),
                                        group(
                                                result.getString(
                                                        "current_status")),
                                        result.getString("spot"),
                                        result
                                                .getTimestamp("created_at")
                                                .toInstant(),
                                        Arrays.asList(
                                                (String[])
                                                        result
                                                                .getArray(
                                                                        "categories")
                                                                .getArray()),
                                        user.getRole() != Role.USER
                                                || Objects.equals(
                                                result.getObject(
                                                        "reporter_id",
                                                        Long.class),
                                                user.getId())));

        return new MapPage(
                List.copyOf(
                        rows.subList(
                                0,
                                Math.min(500, rows.size()))),
                rows.size() > 500);
    }

    @Transactional(readOnly = true)
    public Insights insights() {
        var user = access.requireAuthority();
        var parameters =
                new HashMap<String, Object>();
        String scope = "";

        if (user.getRole() == Role.DEPARTMENT) {
            parameters.put(
                    "department",
                    access.departmentId(user));
            scope = DEPARTMENT_SCOPE;
        }

        var overview =
                jdbc.queryForObject(
                        """
                        SELECT count(*) total,
                          count(*) FILTER(WHERE r.current_status NOT IN ('RESOLVED','REJECTED')) active,
                          count(*) FILTER(WHERE r.current_status='SUBMITTED') submitted,
                          count(*) FILTER(WHERE r.current_status='ASSIGNED') assigned,
                          count(*) FILTER(WHERE r.current_status='IN_PROGRESS') progressing,
                          count(*) FILTER(WHERE r.current_status='RESOLVED') resolved
                        FROM waste_reports r WHERE true
                        """
                                + scope,
                        parameters,
                        (result, number) ->
                                new Overview(
                                        result.getLong("total"),
                                        result.getLong("active"),
                                        result.getLong("submitted"),
                                        result.getLong("assigned"),
                                        result.getLong(
                                                "progressing"),
                                        result.getLong("resolved")));

        if (user.getRole() != Role.ADMIN) {
            return new Insights(
                    overview,
                    List.of(),
                    List.of());
        }

        var spots =
                jdbc.query(
                        """
                        SELECT t.name,count(*) amount FROM waste_reports r JOIN tourist_spots t ON t.id=r.tourist_spot_id
                        WHERE r.current_status<>'REJECTED' GROUP BY t.id,t.name ORDER BY amount DESC,t.name LIMIT 10
                        """,
                        parameters,
                        (result, number) ->
                                new Ranking(
                                        result.getString("name"),
                                        result.getLong("amount")));

        var categories =
                jdbc.query(
                        """
                        SELECT c.name,count(*) amount FROM waste_detections d JOIN waste_categories c ON c.id=d.waste_category_id
                        JOIN waste_reports r ON r.id=d.report_id WHERE r.current_status<>'REJECTED'
                        GROUP BY c.id,c.name ORDER BY amount DESC,c.name LIMIT 10
                        """,
                        parameters,
                        (result, number) ->
                                new Ranking(
                                        result.getString("name"),
                                        result.getLong("amount")));

        return new Insights(
                overview,
                spots,
                categories);
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/service/LocationInsightsService.java from your app here.
