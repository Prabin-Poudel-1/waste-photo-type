package np.chitwancare.config;

import java.util.Base64;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.security.oauth2.server.resource.authentication.*;
import org.springframework.security.web.SecurityFilterChain;
import com.nimbusds.jose.jwk.source.ImmutableSecret;

@Configuration
public class SecurityConfig {
  @Bean SecretKey jwtKey(@Value("${app.auth.jwt-secret}") String encoded) {
    byte[] bytes = Base64.getDecoder().decode(encoded);
    if (bytes.length < 32) throw new IllegalStateException("JWT_SECRET must be base64 containing at least 32 random bytes.");
    return new SecretKeySpec(bytes, "HmacSHA256");
  }
  @Bean PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(12); }
  @Bean JwtEncoder jwtEncoder(SecretKey key) { return new NimbusJwtEncoder(new ImmutableSecret<>(key)); }
  @Bean JwtDecoder jwtDecoder(SecretKey key) {
    var decoder = NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();
    decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer("chitwan-care"));
    return decoder;
  }
  @Bean SecurityFilterChain security(HttpSecurity http) throws Exception {
    var roles = new JwtGrantedAuthoritiesConverter();
    roles.setAuthoritiesClaimName("roles"); roles.setAuthorityPrefix("ROLE_");
    var converter = new JwtAuthenticationConverter(); converter.setJwtGrantedAuthoritiesConverter(roles);
    return http.cors(c -> {}).csrf(c -> c.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(a -> a
          .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
          .requestMatchers("/api/v1/auth/register", "/api/v1/auth/login", "/api/v1/health").permitAll()
          .requestMatchers(HttpMethod.GET, "/api/v1/tourist-spots/**", "/api/v1/waste-categories", "/api/v1/departments").permitAll()
          .requestMatchers("/api/v1/analyses/**").permitAll()
          .requestMatchers(HttpMethod.GET, "/api/v1/maps/reports").authenticated()
          .requestMatchers("/api/v1/admin/management/**").hasRole("ADMIN")
          .requestMatchers("/api/v1/authority/**").hasAnyRole("ADMIN", "DEPARTMENT")
          .requestMatchers(HttpMethod.GET, "/api/v1/reports").hasRole("ADMIN")
          .requestMatchers("/api/v1/reports/**").authenticated()
          .anyRequest().denyAll())
        .oauth2ResourceServer(o -> o.jwt(j -> j.jwtAuthenticationConverter(converter)))
        .build();
  }
}
