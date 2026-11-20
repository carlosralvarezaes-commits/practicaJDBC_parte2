package procedimientos;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;


public class Ejercicio3 {

    public static void renovarPrestamo(int idPrestamo, int diasSolicitados) {
        String sql = "{call renovar_prestamo(?,?,?)}";

        try(Connection con = ConexionBD.getConnection();
            CallableStatement cs = con.prepareCall(sql)) {

            cs.setInt(1, idPrestamo);

            cs.setInt(2,diasSolicitados);
            cs.registerOutParameter(2,Types.INTEGER);

            cs.registerOutParameter(3, Types.DATE);

            cs.execute();



            int concedidos = cs.getInt(2);

            LocalDate fechaNueva = cs.getObject(3, LocalDate.class);
            String fecha= (fechaNueva == null) ? "-" : fechaNueva.toString();

            if(concedidos>0){
                System.out.println("Préstamo " + idPrestamo + ": solicitados " + diasSolicitados
                        + ", concedidos " + concedidos + ". Nueva fecha límite: " + fecha);
            }else{
                System.out.println("Préstamo " + idPrestamo + ": renovación denegada. Fecha límite: " + fecha);
            }



        } catch (SQLException ex) {
            System.out.println("Error al renovar el préstamo " + idPrestamo + ": " + ex.getMessage());
        }


    }

    public static void main(String[] args) {
        renovarPrestamo(1, 7);
        renovarPrestamo(7, 30);
        renovarPrestamo(6, 5);
        renovarPrestamo(2, 5);

        Visor.mostrar("prestamo");
    }
}
