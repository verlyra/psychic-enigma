package com.mycompany.tugaskelompokjwp;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import jdbc.koneksi;

/**
 * Endpoint AJAX untuk simulasi verifikasi pembayaran QRIS / e-wallet.
 * Dipanggil dari order_success.jsp setelah customer "menscan" QRIS dummy.
 * Mengubah status_bayar transaksi menjadi 'terverifikasi'.
 */
@WebServlet("/VerifQris")
public class VerifQrisServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            out.print("{\"ok\":false,\"msg\":\"Sesi tidak valid\"}");
            return;
        }

        int userId;
        try {
            userId = Integer.parseInt((String) session.getAttribute("user_id"));
        } catch (Exception e) {
            out.print("{\"ok\":false,\"msg\":\"User ID tidak valid\"}");
            return;
        }

        String idStr = request.getParameter("order_id");
        if (idStr == null || idStr.isEmpty()) {
            out.print("{\"ok\":false,\"msg\":\"Order ID tidak ditemukan\"}");
            return;
        }

        int orderId;
        try {
            orderId = Integer.parseInt(idStr);
        } catch (NumberFormatException e) {
            out.print("{\"ok\":false,\"msg\":\"Order ID tidak valid\"}");
            return;
        }

        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();

            // Validasi: pastikan order milik user ini, metode e-wallet, dan masih menunggu
            PreparedStatement psChk = conn.prepareStatement(
                "SELECT metode_bayar, status_bayar FROM transaksi WHERE id = ? AND id_user = ?");
            psChk.setInt(1, orderId);
            psChk.setInt(2, userId);
            ResultSet rsChk = psChk.executeQuery();

            if (!rsChk.next()) {
                rsChk.close(); psChk.close(); conn.close();
                out.print("{\"ok\":false,\"msg\":\"Order tidak ditemukan\"}");
                return;
            }

            String metode      = rsChk.getString("metode_bayar");
            String statusBayar = rsChk.getString("status_bayar");
            rsChk.close(); psChk.close();

            if (!"ewallet".equalsIgnoreCase(metode)) {
                conn.close();
                out.print("{\"ok\":false,\"msg\":\"Bukan pembayaran e-wallet\"}");
                return;
            }

            if ("terverifikasi".equalsIgnoreCase(statusBayar)) {
                conn.close();
                out.print("{\"ok\":true,\"msg\":\"Sudah terverifikasi\"}");
                return;
            }

            // Update status menjadi terverifikasi
            PreparedStatement psUpd = conn.prepareStatement(
                "UPDATE transaksi SET status_bayar = 'terverifikasi' WHERE id = ? AND id_user = ?");
            psUpd.setInt(1, orderId);
            psUpd.setInt(2, userId);
            psUpd.executeUpdate();
            psUpd.close();
            conn.close();

            out.print("{\"ok\":true,\"msg\":\"Pembayaran berhasil diverifikasi\"}");

        } catch (Exception e) {
            out.print("{\"ok\":false,\"msg\":\"Error: " + e.getMessage() + "\"}");
        }
    }
}
