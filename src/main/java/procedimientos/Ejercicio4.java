package procedimientos;

public class Ejercicio4 {

    public static void avisarVencimientos(int idSocio, int diasSolicitados) {

        String sql ="{call avisar_vencimientos(?,?,?)}";







    }

    public static void main(String[] args) {
        avisarVencimientos(1, 10);
        avisarVencimientos(3, 0);
        avisarVencimientos(2, 45);
        avisarVencimientos(99, 5);

        Visor.mostrar("aviso");
    }
}
