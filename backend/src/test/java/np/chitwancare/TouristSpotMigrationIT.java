package np.chitwancare;

import static org.junit.jupiter.api.Assertions.*;

import java.util.UUID;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest(
        webEnvironment =
                SpringBootTest.WebEnvironment.RANDOM_PORT)
class TouristSpotMigrationIT {
    @Autowired DataSource dataSource;
    @Autowired JdbcTemplate jdbc;

    @Test
    void upgradeFromV2PreservesExistingReportDetectionsAndHistory() {
        // Isolated random test schema. Never clean/recreate the application's database or volume.
        String schema =
                "upgrade_"
                        + UUID.randomUUID()
                        .toString()
                        .replace("-", "");

        var baseline =
                Flyway.configure()
                        .dataSource(dataSource)
                        .schemas(schema)
                        .defaultSchema(schema)
                        .target("2")
                        .load();

        try {
            baseline.migrate();

            long id =
                    jdbc.queryForObject(
                            "insert into "
                                    + schema
                                    + ".waste_reports(description,latitude,longitude,severity,current_status)"
                                    + " values('Existing Phase 2 report',27.68,84.43,'MEDIUM','SUBMITTED') returning"
                                    + " id",
                            Long.class);

            jdbc.update(
                    "insert into "
                            + schema
                            + ".waste_detections(report_id,waste_category_id,detected_label,confidence)"
                            + " values(?,1,'Plastic',0.94),(?,5,'Organic',0.82)",
                    id,
                    id);

            jdbc.update(
                    "insert into "
                            + schema
                            + ".report_status_history(report_id,status,note) values(?,'SUBMITTED','Existing"
                            + " timeline entry')",
                    id);

            var before =
                    jdbc.queryForMap(
                            "select"
                                    + " id,description,latitude,longitude,severity,current_status,created_at,updated_at"
                                    + " from "
                                    + schema
                                    + ".waste_reports where id=?",
                            id);

            var history =
                    jdbc.queryForList(
                            "select * from "
                                    + schema
                                    + ".report_status_history where report_id=?",
                            id);

            var detections =
                    jdbc.queryForList(
                            "select * from "
                                    + schema
                                    + ".waste_detections where report_id=? order by id",
                            id);

            var upgrade =
                    Flyway.configure()
                            .dataSource(dataSource)
                            .schemas(schema)
                            .defaultSchema(schema)
                            .load();

            assertEquals(
                    1,
                    upgrade.migrate()
                            .migrationsExecuted);

            assertEquals(
                    before,
                    jdbc.queryForMap(
                            "select"
                                    + " id,description,latitude,longitude,severity,current_status,created_at,updated_at"
                                    + " from "
                                    + schema
                                    + ".waste_reports where id=?",
                            id));

            assertEquals(
                    history,
                    jdbc.queryForList(
                            "select * from "
                                    + schema
                                    + ".report_status_history where report_id=?",
                            id));

            assertEquals(
                    detections,
                    jdbc.queryForList(
                            "select * from "
                                    + schema
                                    + ".waste_detections where report_id=? order by id",
                            id));

            assertNull(
                    jdbc.queryForObject(
                            "select tourist_spot_id from "
                                    + schema
                                    + ".waste_reports where id=?",
                            Long.class,
                            id));

            assertEquals(
                    0,
                    jdbc.queryForObject(
                            "select count(*) from "
                                    + schema
                                    + ".tourist_spots",
                            Integer.class));

            assertEquals(
                    0,
                    upgrade.migrate()
                            .migrationsExecuted);
        } finally {
            // Only the UUID schema created by this test is removed, including its synthetic fixtures.
            jdbc.execute(
                    "drop schema if exists "
                            + schema
                            + " cascade");
        }
    }
}// Placeholder: paste the contents of backend/src/test/java/np/chitwancare/TouristSpotMigrationIT.java from your app here.
