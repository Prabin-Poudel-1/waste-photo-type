package np.chitwancare.config;

import java.util.Arrays;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.*;

@Configuration
public class WebConfig implements WebMvcConfigurer {
  private final String[] origins;

  public WebConfig(@Value("${app.cors.allowed-origins}") String origins) {
    this.origins =
        Arrays.stream(origins.split(","))
            .map(String::trim)
            .filter(s -> !s.isBlank())
            .toArray(String[]::new);
  }

  @Override
  public void addCorsMappings(CorsRegistry registry) {
    registry
        .addMapping("/api/v1/**")
        .allowedOrigins(origins)
        .allowedMethods("GET", "POST", "OPTIONS")
        .allowedHeaders("Content-Type", "Accept", "Authorization")
        .allowCredentials(false)
        .maxAge(3600);
  }
}
