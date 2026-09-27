package np.chitwancare.controller;
import jakarta.validation.Valid;
import np.chitwancare.dto.AuthDtos;
import np.chitwancare.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
  private final AuthService service;
  public AuthController(AuthService service) { this.service=service; }
  @PostMapping("/register") @ResponseStatus(HttpStatus.CREATED)
  public AuthDtos.Token register(@Valid @RequestBody AuthDtos.Register request) { return service.register(request); }
  @PostMapping("/login")
  public AuthDtos.Token login(@Valid @RequestBody AuthDtos.Login request) { return service.login(request); }
}
