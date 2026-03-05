using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using BCrypt.Net;
using System.Security.Claims;
using System.Text;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserService _userService;
    private readonly EmailService _emailService;

    public AuthController(UserService userService, EmailService emailService)
    {
        _userService = userService;
        _emailService = emailService;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
    {
        var user = await _userService.GetByEmailAsync(request.Email);

        if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return Unauthorized("Credenciales inválidas");
        }

        if (!user.IsEmailVerified)
        {
            return BadRequest("Correo no verificado. Por favor verifica tu cuenta.");
        }

        // Generate Token
        var token = $"token-{Guid.NewGuid()}"; // Still mock until JWT middleware is setup

        return Ok(new LoginResponse
        {
            Token = token,
            FullName = user.FullName,
            Role = user.Role
        });
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(User newUser)
    {
        if (string.IsNullOrEmpty(newUser.Email) || string.IsNullOrEmpty(newUser.PasswordHash)) 
            return BadRequest("Datos incompletos");

        var existing = await _userService.GetByEmailAsync(newUser.Email);
        if (existing is not null)
        {
            return BadRequest("El correo ya está registrado");
        }

        // Hash password (the field Name is PasswordHash but frontend sends plain password initially here for registration convenience)
        var plainPassword = newUser.PasswordHash; 
        newUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword(plainPassword);
        
        // Generate Verification Code
        var code = new Random().Next(100000, 999999).ToString();
        newUser.VerificationCode = code;
        newUser.IsEmailVerified = false;

        await _userService.CreateAsync(newUser);
        await _emailService.SendVerificationCodeAsync(newUser.Email, code);

        return Ok("Usuario registrado. Por favor revisa tu correo para el código de verificación.");
    }

    [HttpPost("verify")]
    public async Task<IActionResult> Verify(VerifyRequest request)
    {
        var user = await _userService.GetByEmailAsync(request.Email);
        if (user == null) return NotFound("Usuario no encontrado");

        if (user.VerificationCode == request.Code)
        {
            user.IsEmailVerified = true;
            user.VerificationCode = null;
            await _userService.UpdateAsync(user.Id!, user);
            return Ok("Cuenta verificada con éxito");
        }

        return BadRequest("Código de verificación incorrecto");
    }
}

public class VerifyRequest {
    public string Email { get; set; } = null!;
    public string Code { get; set; } = null!;
}
