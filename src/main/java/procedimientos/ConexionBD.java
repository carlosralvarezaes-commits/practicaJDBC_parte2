package procedimientos;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class ConexionBD {
    private static final Properties config = new Properties();

    static {
        try (InputStream in = new FileInputStream("db.properties")) {
            config.load(in);
        } catch (IOException ex) {
            throw new ExceptionInInitializerError(
                    "No se pudo leer db.properties: " + ex.getMessage());
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(
                config.getProperty("db.url"),
                config.getProperty("db.user"),
                config.getProperty("db.password"));
    }
}
