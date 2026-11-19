package procedimientos;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;

public class Ejercicio2 {

    public static void devolverLibro(int idPrestamo) {
        String sql = "{call devolver_libro(?,?)}"; //Uno es IN y el Otro es OUT

        try(Connection con = ConexionBD.getConnection();
            CallableStatement cs = con.prepareCall(sql)) {

            //ENTRADA

            //Cuando es IN se hace con set(tipo de variable )  en este caso Int
            cs.setInt(1,idPrestamo);//Numero de posicion, y la variable que debe ser del mismo tipo que el set


            //SALIDA

            //Numero de posicion en este caso es el 2, y de tipo Integer
            cs.registerOutParameter(2, Types.INTEGER);
            //Aqui se indica que el de salida esta en poscion 2 y es de tipo Integer

            cs.execute();

            //leo lo que estoy enviandole a SQL
            int retraso = cs.getInt(2);

            if(retraso<0 ){
                System.out.println("Prestamo "+idPrestamo+ ": No existe o ya estaba devuelto");
            } else if (retraso==0) {
                System.out.println("Prestamo "+idPrestamo+ ": Devuelto en Plazo ");
            } else if (retraso>0) {
                System.out.println("Prestamo "+idPrestamo+ ": Devuelto con "+ retraso +" dia(s) de retraso");
            }


        }catch (SQLException sqlException){
            System.err.println("Error al devolver el prestamo  "+idPrestamo + ": "+sqlException.getMessage());

        }


    }

    public static void main(String[] args) {
        devolverLibro(1);
        devolverLibro(2);
        devolverLibro(3);
        devolverLibro(99);

        Visor.mostrar("prestamo");
        Visor.mostrar("libro");
    }
}
