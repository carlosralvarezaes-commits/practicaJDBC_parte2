package procedimientos;

import java.sql.*;

public class Ejercicio4 {

    public static void avisarVencimientos(int idSocio, int diasSolicitados) {

        String sql ="{call avisar_vencimientos(?,?,?)}";


        try(Connection con = ConexionBD.getConnection();
            CallableStatement cs = con.prepareCall(sql)){

            cs.setInt(1,idSocio); // Set ya que es IN
            cs.registerOutParameter(1, Types.INTEGER); // registerOutParameter porque es OUT
            cs.setInt(2, diasSolicitados);
            cs.registerOutParameter(2,Types.INTEGER);

            System.out.println("Socio: "+ idSocio+ " (pedidos "+ diasSolicitados+ " dias): ");


            int avisos= 0 ;
            try(ResultSet rs = cs.executeQuery()){
                while(rs.next()){
                    avisos++;
                }
            }


            int ventana = cs.getInt(2);
            int vencidos =cs.getInt(3);

        }catch (SQLException ex){
            System.err.println("Error del SQL ");
        }







    }

    public static void main(String[] args) {
        avisarVencimientos(1, 10);
        avisarVencimientos(3, 0);
        avisarVencimientos(2, 45);
        avisarVencimientos(99, 5);

        Visor.mostrar("aviso");
    }
}
