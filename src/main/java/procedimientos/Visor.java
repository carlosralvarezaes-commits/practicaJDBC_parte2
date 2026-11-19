package procedimientos;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;

public class Visor {

    public static void mostrar(String tabla) {
        try (Connection con = ConexionBD.getConnection();
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT * FROM " + tabla)) {

            ResultSetMetaData md = rs.getMetaData();
            int columnas = md.getColumnCount();
            System.out.println("\n--- " + tabla.toUpperCase() + " ---");
            for (int i = 1; i <= columnas; i++) {
                System.out.printf("%-20s", md.getColumnLabel(i));
            }
            System.out.println();
            while (rs.next()) {
                for (int i = 1; i <= columnas; i++) {
                    System.out.printf("%-20s", rs.getString(i));
                }
                System.out.println();
            }
        } catch (SQLException ex) {
            System.err.println("No se pudo mostrar " + tabla + ": " + ex.getMessage());
        }
    }
}
