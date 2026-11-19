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

            //Se hace el set porque es IN
            cs.setInt(1, idPrestamo);

            //Integer de los dias se hace tanto lo del Int porque es IN como el Types.INTEGER por OUT
            cs.setInt(2,diasSolicitados);
            cs.registerOutParameter(2,Types.INTEGER);

            //Solo se realiza el OUT osea explicar que es tipo es este caso types.DATE
            cs.registerOutParameter(3, Types.DATE);



            cs.execute();

            int concedidos = cs.getInt(2);
            LocalDate fechaNueva = cs.getObject(3, LocalDate.class);

            //Si (condicion) ? -> explica que es condicion
            //Es nula -> "-"
            //No es nula entonces fechaNueva transformar a String
            String fecha = (fechaNueva==null) ? "-" : fechaNueva.toString();

            if (concedidos > 0) {
                System.out.println("Préstamo " + idPrestamo + ": solicitados " + diasSolicitados
                        + ", concedidos " + concedidos + ". Nueva fecha límite: " + fecha);
            } else {
                System.out.println("Préstamo " + idPrestamo + ": renovación denegada. Fecha límite: " + fecha);
            }



        } catch (SQLException ex) {
            System.out.println("Error al renovar el préstamo " + idPrestamo + ": " + ex.getMessage());        }


    }

    public static void main(String[] args) {
        renovarPrestamo(1, 7);
        renovarPrestamo(7, 30);
        renovarPrestamo(6, 5);
        renovarPrestamo(2, 5);

        Visor.mostrar("prestamo");
    }
}
