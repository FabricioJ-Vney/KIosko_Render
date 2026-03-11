namespace Kritik.Backend.Services;

public class EmailService
{
    private readonly ILogger<EmailService> _logger;

    public EmailService(ILogger<EmailService> logger)
    {
        _logger = logger;
    }

    public async Task SendVerificationCodeAsync(string email, string code)
    {
        // For MVP, we just log to console
        // This will be visible in Render environment logs
        var message = $@"
        =================================================
        PARA: {email}
        ASUNTO: Tu código de verificación de Kritik
        MENSAJE: Tu código es: {code}
        =================================================";
        
        _logger.LogInformation(message);
        Console.WriteLine(message);
        
        await Task.CompletedTask;
    }
}
