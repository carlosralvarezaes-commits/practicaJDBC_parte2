package procedimientos;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;


public class Ejercicio3 {

    public static void renovarPrestamo(int idPrestamo, int diasSolicitados) {
        String sql = "{call renovar_presatamo(?,?,?)}";

        try(Connection con = ConexionBD.getConnection();
            CallableStatement cs = con.prepareCall(sql)) {

            cs.setInt(1, idPrestamo);

            cs.setInt(2,diasSolicitados);
            cs.registerOutParameter(2,Types.INTEGER);

            cs.setObject(3, LocalDate.now());
            cs.registerOutParameter(3, Types.DATE);

            cs.execute();



            int concedidos = cs.getInt(2);

            LocalDate fechaNueva = cs.getObject(3, LocalDate.class);

            if(concedidos>0){
                System.out.println("Prestamo: "+ idPrestamo+ " Solicitados: "+ diasSolicitados+ " Concedidos: "+ concedidos+ " Nueva fechaNueva Limite: "+ fechaNueva);
            }else{
                System.out.println();
            }



        } catch (SQLException e) {
            throw new RuntimeException(e);
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
