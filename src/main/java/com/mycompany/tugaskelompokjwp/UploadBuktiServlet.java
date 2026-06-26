package com.mycompany.tugaskelompokjwp;

import java.io.File;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

import jdbc.koneksi;

/**
 * Menerima upload bukti transfer dari customer, menyimpan filenya ke folder
 * /uploads/bukti pada webapp, lalu menyimpan path-nya di tabel transaksi.
 */
@WebServlet("/UploadBukti")
@MultipartConfig(maxFileSize = 5 * 1024 * 1024) // maks 5 MB
public class UploadBuktiServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, java.io.IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        int userId = Integer.parseInt((String) session.getAttribute("user_id"));

        String idStr = request.getParameter("order_id");
        if (idStr == null) { response.sendRedirect("order_history.jsp"); return; }

        int orderId;
        try { orderId = Integer.parseInt(idStr); }
        catch (NumberFormatException e) { response.sendRedirect("order_history.jsp"); return; }

        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();

            // Pastikan order memang milik user ini dan berupa transfer
            PreparedStatement psChk = conn.prepareStatement(
                "SELECT metode_bayar FROM transaksi WHERE id = ? AND id_user = ?");
            psChk.setInt(1, orderId);
            psChk.setInt(2, userId);
            ResultSet rsChk = psChk.executeQuery();
            boolean valid = false;
            String metode = "";
            if (rsChk.next()) { valid = true; metode = rsChk.getString("metode_bayar"); }
            rsChk.close(); psChk.close();

            if (!valid || !"transfer".equalsIgnoreCase(metode)) {
                conn.close();
                response.sendRedirect("order_history.jsp");
                return;
            }

            Part filePart = request.getPart("bukti");
            if (filePart == null || filePart.getSize() == 0) {
                conn.close();
                response.sendRedirect("order_history.jsp?upload=empty");
                return;
            }

            // Tentukan ekstensi dari nama file asli
            String submitted = filePart.getSubmittedFileName();
            String ext = "png";
            if (submitted != null && submitted.contains(".")) {
                ext = submitted.substring(submitted.lastIndexOf('.') + 1).toLowerCase();
                if (!ext.matches("png|jpg|jpeg|gif|webp")) ext = "png";
            }

            String fileName = "bukti_" + orderId + "_" + System.currentTimeMillis() + "." + ext;

            // Simpan ke /uploads/bukti pada direktori webapp yang ter-deploy
            String baseDir = getServletContext().getRealPath("/uploads/bukti");
            File dir = new File(baseDir);
            if (!dir.exists()) dir.mkdirs();

            Path target = Paths.get(baseDir, fileName);
            try (InputStream in = filePart.getInputStream()) {
                Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
            }

            String webPath = "uploads/bukti/" + fileName;

            PreparedStatement psUpd = conn.prepareStatement(
                "UPDATE transaksi SET bukti_transfer = ?, status_bayar = 'menunggu' WHERE id = ? AND id_user = ?");
            psUpd.setString(1, webPath);
            psUpd.setInt(2, orderId);
            psUpd.setInt(3, userId);
            psUpd.executeUpdate();
            psUpd.close();
            conn.close();

            response.sendRedirect("order_history.jsp?upload=ok");
        } catch (Exception e) {
            response.sendRedirect("order_history.jsp?upload=error");
        }
    }
}
