/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package jdbc;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class koneksi {
    public Connection bukaKoneksi() throws SQLException {
        Connection connect;
        try {
            // Gunakan driver yang lebih baru jika menggunakan MySQL Connector 8.0+
            Class.forName("com.mysql.cj.jdbc.Driver"); 
            connect = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/kasir_supermarket", "root", "");
            return connect;
        } catch (Exception exc) {
            System.out.println("Error: " + exc.getMessage());
        }
        return null;
    }
}