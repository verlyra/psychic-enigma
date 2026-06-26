package jdbc;

import java.sql.Connection;
import java.sql.Statement;

/**
 * Memastikan skema database lengkap untuk fitur pembayaran, pengiriman,
 * pembatalan, dan diskon. Semua perintah bersifat idempoten (aman dijalankan
 * berulang) sehingga aplikasi tetap berjalan walau migrasi SQL belum dijalankan
 * manual di phpMyAdmin.
 */
public class DbInit {

    private static boolean done = false;

    /** Dipanggil sekali per proses; mengabaikan error "kolom sudah ada" dsb. */
    public static synchronized void ensureSchema(Connection conn) {
        if (done || conn == null) return;
        // Kolom tambahan pada tabel transaksi
        runQuiet(conn, "ALTER TABLE transaksi ADD COLUMN metode_bayar VARCHAR(20) NOT NULL DEFAULT 'transfer'");
        runQuiet(conn, "ALTER TABLE transaksi ADD COLUMN bukti_transfer VARCHAR(255) NULL");
        runQuiet(conn, "ALTER TABLE transaksi ADD COLUMN status_bayar VARCHAR(20) NOT NULL DEFAULT 'terverifikasi'");
        runQuiet(conn, "ALTER TABLE transaksi ADD COLUMN metode_kirim VARCHAR(20) NOT NULL DEFAULT 'reguler'");
        runQuiet(conn, "ALTER TABLE transaksi ADD COLUMN ongkir DECIMAL(15,2) NOT NULL DEFAULT 0");
        runQuiet(conn, "ALTER TABLE transaksi ADD COLUMN diskon DECIMAL(15,2) NOT NULL DEFAULT 0");
        runQuiet(conn, "ALTER TABLE transaksi ADD COLUMN kode_voucher VARCHAR(50) NULL");
        runQuiet(conn, "ALTER TABLE transaksi ADD COLUMN cancel_requested TINYINT(1) NOT NULL DEFAULT 0");
        // Pastikan kolom status bisa menampung 'dibatalkan' (ubah enum lama -> varchar)
        runQuiet(conn, "ALTER TABLE transaksi ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending'");
        runQuiet(conn, "ALTER TABLE transaksi MODIFY COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending'");

        // Master pengiriman (ongkos kirim bisa diatur admin)
        runQuiet(conn,
            "CREATE TABLE IF NOT EXISTS master_pengiriman (" +
            "  id INT AUTO_INCREMENT PRIMARY KEY," +
            "  kode VARCHAR(20) NOT NULL UNIQUE," +
            "  nama VARCHAR(50) NOT NULL," +
            "  biaya DECIMAL(15,2) NOT NULL DEFAULT 0," +
            "  estimasi VARCHAR(50) DEFAULT NULL," +
            "  aktif TINYINT(1) NOT NULL DEFAULT 1" +
            ")");
        runQuiet(conn,
            "INSERT IGNORE INTO master_pengiriman (id, kode, nama, biaya, estimasi, aktif) VALUES " +
            "(1,'instant','Kurir Instant',20000,'1-3 jam',1)," +
            "(2,'sameday','Kurir Sameday',15000,'Hari ini',1)," +
            "(3,'reguler','Kurir Reguler',9000,'2-4 hari',1)");

        // Master diskon / promo / voucher
        runQuiet(conn,
            "CREATE TABLE IF NOT EXISTS master_diskon (" +
            "  id INT AUTO_INCREMENT PRIMARY KEY," +
            "  nama VARCHAR(100) NOT NULL," +
            "  tipe VARCHAR(10) NOT NULL DEFAULT 'auto'," +        // auto | voucher
            "  kode VARCHAR(50) DEFAULT NULL," +
            "  jenis_potongan VARCHAR(10) NOT NULL DEFAULT 'nominal'," + // persen | nominal
            "  nilai DECIMAL(15,2) NOT NULL DEFAULT 0," +
            "  min_belanja DECIMAL(15,2) NOT NULL DEFAULT 0," +
            "  maks_potongan DECIMAL(15,2) NOT NULL DEFAULT 0," +
            "  aktif TINYINT(1) NOT NULL DEFAULT 1," +
            "  tanggal_mulai DATE DEFAULT NULL," +
            "  tanggal_selesai DATE DEFAULT NULL" +
            ")");
        runQuiet(conn,
            "INSERT IGNORE INTO master_diskon " +
            "(id, nama, tipe, kode, jenis_potongan, nilai, min_belanja, maks_potongan, aktif) VALUES " +
            "(1,'Diskon 10% Min. 50RB','auto',NULL,'persen',10,50000,20000,1)," +
            "(2,'Voucher HEMAT5K','voucher','HEMAT5K','nominal',5000,0,0,1)," +
            "(3,'Voucher NEWBIE 15%','voucher','NEWBIE','persen',15,30000,25000,1)");

        done = true;
    }

    private static void runQuiet(Connection conn, String sql) {
        try (Statement st = conn.createStatement()) {
            st.execute(sql);
        } catch (Exception ignored) {
            // kolom/tabel sudah ada atau tidak didukung -> abaikan
        }
    }
}
