package jdbc;

import java.sql.Connection;
import java.sql.Statement;

public class SetupDb {
    public static void main(String[] args) {
        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
            if (conn != null) {
                Statement stmt = conn.createStatement();
                
                // Create master_kategori table
                stmt.execute("CREATE TABLE IF NOT EXISTS master_kategori (" +
                             "id INT AUTO_INCREMENT PRIMARY KEY, " +
                             "nama_kategori VARCHAR(255) NOT NULL" +
                             ")");
                System.out.println("Table master_kategori created.");
                
                // Add some default categories if empty
                stmt.execute("INSERT IGNORE INTO master_kategori (id, nama_kategori) VALUES (1, 'FOOD'), (2, 'DRINK'), (3, 'SNACK'), (4, 'OTHER')");
                
                // Add id_kategori to master_product if not exists
                try {
                    stmt.execute("ALTER TABLE master_product ADD COLUMN id_kategori INT");
                    System.out.println("Column id_kategori added.");
                    
                    // Map existing categories to id_kategori
                    stmt.execute("UPDATE master_product SET id_kategori = 1 WHERE kategori = 'FOOD'");
                    stmt.execute("UPDATE master_product SET id_kategori = 2 WHERE kategori = 'DRINK'");
                    stmt.execute("UPDATE master_product SET id_kategori = 3 WHERE kategori = 'SNACK'");
                    stmt.execute("UPDATE master_product SET id_kategori = 4 WHERE kategori = 'OTHER'");
                    
                } catch (Exception e) {
                    System.out.println("Column id_kategori might already exist: " + e.getMessage());
                }
                
                stmt.close();
                conn.close();
                System.out.println("Setup completed successfully.");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
