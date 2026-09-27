package np.chitwancare.service;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import np.chitwancare.dto.AuthDtos;
import np.chitwancare.entity.AppUser;
import np.chitwancare.enums.Role;
import np.chitwancare.repository.AppUserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {
    private final AppUserRepository users;
    private final PasswordEncoder passwords;
    private final JwtEncoder tokens;
    private final String dummyHash;

    public AuthService(
            AppUserRepository users,
            PasswordEncoder passwords,
            JwtEncoder tokens) {
        this.users = users;
        this.passwords = passwords;
        this.tokens = tokens;
        dummyHash =
                passwords.encode(
                        UUID.randomUUID().toString());
    }

    @Transactional
    public AuthDtos.Token register(
            AuthDtos.Register request) {
        validatePassword(request.password());

        String email =
                request
                        .email()
                        .trim()
                        .toLowerCase(Locale.ROOT);

        if (users.findByEmail(email).isPresent()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "This email is already registered.");
        }

        var user = new AppUser();
        user.setName(request.name().trim());
        user.setEmail(email);
        user.setPasswordHash(
                passwords.encode(request.password()));
        user.setRole(Role.USER);
        user.setActive(true);

        return token(users.saveAndFlush(user));
    }

    @Transactional(readOnly = true)
    public AuthDtos.Token login(
            AuthDtos.Login request) {
        validatePassword(request.password());

        var user =
                users
                        .findByEmail(
                                request
                                        .email()
                                        .trim()
                                        .toLowerCase(Locale.ROOT))
                        .orElse(null);

        String hash =
                user == null
                        || user.getPasswordHash() == null
                        ? dummyHash
                        : user.getPasswordHash();

        boolean matches =
                passwords.matches(
                        request.password(),
                        hash);

        if (!matches
                || user == null
                || !user.isActive()
                || user.getPasswordHash() == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Email or password is incorrect.");
        }

        return token(user);
    }

    private void validatePassword(
            String password) {
        if (password
                .getBytes(StandardCharsets.UTF_8)
                .length
                > 72) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Password must be at most 72 UTF-8 bytes.");
        }
    }

    private AuthDtos.Token token(
            AppUser user) {
        Instant now = Instant.now();
        Instant expires =
                now.plus(Duration.ofDays(7));

        var claims =
                JwtClaimsSet.builder()
                        .issuer("chitwan-care")
                        .subject(user.getId().toString())
                        .issuedAt(now)
                        .expiresAt(expires)
                        .claim(
                                "roles",
                                List.of(
                                        user.getRole().name()))
                        .build();

        String jwt =
                tokens
                        .encode(
                                JwtEncoderParameters.from(
                                        JwsHeader
                                                .with(MacAlgorithm.HS256)
                                                .build(),
                                        claims))
                        .getTokenValue();

        return new AuthDtos.Token(
                jwt,
                "Bearer",
                expires,
                new AuthDtos.User(
                        user.getId(),
                        user.getName(),
                        user.getEmail(),
                        user.getRole().name()));
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/service/AuthService.java from your app here.
