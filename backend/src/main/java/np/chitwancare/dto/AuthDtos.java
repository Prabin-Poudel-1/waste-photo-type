package np.chitwancare.dto;
import jakarta.validation.constraints.*;
import java.time.Instant;

public final class AuthDtos {
  private AuthDtos() {}
  public record Register(@NotBlank @Size(max=120) String name,
      @NotBlank @Email @Size(max=254) String email, @NotBlank @Size(min=8,max=72) String password) {}
  public record Login(@NotBlank @Email @Size(max=254) String email,
      @NotBlank @Size(max=72) String password) {}
  public record User(Long id, String name, String email, String role) {}
  public record Token(String token, String tokenType, Instant expiresAt, User user) {}
}
