package procedimientos;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;

public class Ejercicio1 {

    public static void bloquearMorosos()  {
        String sql ="{call bloquear_morosos(?)} "; // Se utilizan llaves para llamar al metodo (obligatorio), en este caso es solo un OUT, el cual es para p_bloqueados

        try(Connection con = ConexionBD.getConnection();
            CallableStatement cs = con.prepareCall(sql)){

            //register OUT Parameter se utiliza para especificar que el parametro 1 en este caso va de salida y especifica el tipo de dato que es
            cs.registerOutParameter(1, Types.INTEGER); // (static final) Constante de diferentes tipos en este caso integer

            cs.execute();//Ejecuta lo pedido, no usa executeQuery porque no devuelve nada todo OUT

            //lee el valor que va de salida. El 1 explica el lugar donde esta el parametro entre todos los (?)
            int bloqueados = cs.getInt(1);
            System.out.println("Socios bloqueados: "+bloqueados);

        }catch (SQLException sqlException){
            System.err.println("Error del SQL: "+sqlException.getMessage());
        }




    }

    public static void main(String[] args) {
        bloquearMorosos();
        bloquearMorosos();

        Visor.mostrar("socio");
    }
}
//Terminado - Por subir (X)

//Guia - (X) -> NO y (V) ->SI