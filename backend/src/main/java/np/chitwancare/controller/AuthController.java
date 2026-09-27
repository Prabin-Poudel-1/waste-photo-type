package np.chitwancare.controller;

import jakarta.validation.Valid;
import np.chitwancare.dto.AuthDtos;
import np.chitwancare.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthService service;

    public AuthController(AuthService service) {
        this.service = service;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthDtos.Token register(
            @Valid @RequestBody AuthDtos.Register request) {
        return service.register(request);
    }

    @PostMapping("/login")
    public AuthDtos.Token login(
            @Valid @RequestBody AuthDtos.Login request) {
        return service.login(request);
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/controller/AuthController.java from your app here.
