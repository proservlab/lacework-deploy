import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Log4jDemo {
    private static final Logger logger = LogManager.getLogger(Log4jDemo.class);

    public static void main(String[] args) {
        String userMessage = args.length > 0 ? args[0] : "Hello, World!";
        logger.info("User message: {}", userMessage);
    }
}