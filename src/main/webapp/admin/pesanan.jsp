<%@page import="jdbc.koneksi"%>
<%@page import="jdbc.DbInit"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    static final String[] FLOW       = {"pending", "diproses", "dipacking", "dikirim", "selesai"};
    static final String[] FLOW_LABEL = {"Pending", "Diproses", "Dipacking", "Dikirim", "Selesai"};

    boolean isValidStatus(String s) {
        if (s == null) return false;
        for (String f : FLOW) if (f.equals(s)) return true;
        return false;
    }
    String statusBadge(String s) {
        switch (s == null ? "pending" : s.trim().toLowerCase()) {
            case "diproses":   return "bg-[#3498DB] text-white";
            case "dipacking":  return "bg-[#A855F7] text-white";
            case "dikirim":    return "bg-[#FB923C] text-black";
            case "selesai":    return "bg-[#4ADE80] text-black";
            case "dibatalkan": return "bg-red-400 text-black";
            default:           return "bg-gray-300 text-black";
        }
    }
    String bayarBadge(String s) {
        switch (s == null ? "menunggu" : s.trim().toLowerCase()) {
            case "terverifikasi": return "bg-[#4ADE80] text-black";
            case "ditolak":       return "bg-red-400 text-black";
            default:              return "bg-gray-300 text-black";
        }
    }
%>
<%
    if (session.getAttribute("user_id") == null || !"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String flashMsg = "";
    String action   = request.getParameter("action");
    String curFilter = request.getParameter("filter");
    if (curFilter == null) curFilter = "";
    String redirectQS = curFilter.isEmpty() ? "" : ("?filter=" + curFilter);

    // ---------- PAGINATION ----------
    int perPage = 10;
    try { perPage = Integer.parseInt(request.getParameter("per_page")); } catch (Exception ignore) {}
    if (perPage != 5 && perPage != 10 && perPage != 25) perPage = 10;
    int pageNum = 1;
    try { pageNum = Integer.parseInt(request.getParameter("page")); } catch (Exception ignore) {}
    if (pageNum < 1) pageNum = 1;
    int totalRows = 0, totalPages = 1, offset = 0;

    // ---------- AKSI ADMIN ----------
    if ("POST".equalsIgnoreCase(request.getMethod()) && action != null) {
        String idStr = request.getParameter("id");
        try {
            int oid = Integer.parseInt(idStr);
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
            DbInit.ensureSchema(conn);

            if ("update_status".equals(action)) {
                String ns = request.getParameter("status");
                if (isValidStatus(ns)) {
                    PreparedStatement ps = conn.prepareStatement("UPDATE transaksi SET status=? WHERE id=?");
                    ps.setString(1, ns); ps.setInt(2, oid); ps.executeUpdate(); ps.close();
                    flashMsg = "Status order #" + oid + " -> " + ns.toUpperCase();
                }
            } else if ("verify_payment".equals(action)) {
                PreparedStatement ps = conn.prepareStatement("UPDATE transaksi SET status_bayar='terverifikasi' WHERE id=?");
                ps.setInt(1, oid); ps.executeUpdate(); ps.close();
                flashMsg = "Pembayaran order #" + oid + " diverifikasi.";
            } else if ("reject_payment".equals(action)) {
                // Tolak pembayaran → batalkan order + kembalikan stok
                conn.setAutoCommit(false);
                try {
                    String curStatus = null;
                    PreparedStatement psS = conn.prepareStatement("SELECT status FROM transaksi WHERE id=?");
                    psS.setInt(1, oid); ResultSet rsS = psS.executeQuery();
                    if (rsS.next()) curStatus = rsS.getString("status");
                    rsS.close(); psS.close();

                    // Kembalikan stok jika belum dibatalkan sebelumnya
                    if (curStatus != null && !"dibatalkan".equalsIgnoreCase(curStatus)) {
                        PreparedStatement psD = conn.prepareStatement("SELECT id_product, qty FROM detail_transaksi WHERE id_transaksi=?");
                        psD.setInt(1, oid); ResultSet rsD = psD.executeQuery();
                        while (rsD.next()) {
                            PreparedStatement psU = conn.prepareStatement("UPDATE master_product SET stok = stok + ? WHERE id = ?");
                            psU.setInt(1, rsD.getInt("qty")); psU.setInt(2, rsD.getInt("id_product"));
                            psU.executeUpdate(); psU.close();
                        }
                        rsD.close(); psD.close();
                    }

                    // Set status_bayar=ditolak DAN status=dibatalkan sekaligus
                    PreparedStatement psT = conn.prepareStatement(
                        "UPDATE transaksi SET status_bayar='ditolak', status='dibatalkan', cancel_requested=0 WHERE id=?");
                    psT.setInt(1, oid); psT.executeUpdate(); psT.close();

                    conn.commit();
                    flashMsg = "Pembayaran order #" + oid + " ditolak. Pesanan otomatis dibatalkan & stok dikembalikan.";
                } catch (Exception ex) {
                    conn.rollback();
                    flashMsg = "Gagal menolak pembayaran: " + ex.getMessage();
                } finally {
                    conn.setAutoCommit(true);
                }
            } else if ("confirm_cancel".equals(action)) {
                // Kembalikan stok lalu set status dibatalkan
                conn.setAutoCommit(false);
                try {
                    String curStatus = null;
                    PreparedStatement psS = conn.prepareStatement("SELECT status FROM transaksi WHERE id=?");
                    psS.setInt(1, oid); ResultSet rsS = psS.executeQuery();
                    if (rsS.next()) curStatus = rsS.getString("status");
                    rsS.close(); psS.close();

                    if (curStatus != null && !"dibatalkan".equalsIgnoreCase(curStatus)) {
                        PreparedStatement psD = conn.prepareStatement("SELECT id_product, qty FROM detail_transaksi WHERE id_transaksi=?");
                        psD.setInt(1, oid); ResultSet rsD = psD.executeQuery();
                        while (rsD.next()) {
                            PreparedStatement psU = conn.prepareStatement("UPDATE master_product SET stok = stok + ? WHERE id = ?");
                            psU.setInt(1, rsD.getInt("qty")); psU.setInt(2, rsD.getInt("id_product"));
                            psU.executeUpdate(); psU.close();
                        }
                        rsD.close(); psD.close();

                        PreparedStatement psT = conn.prepareStatement("UPDATE transaksi SET status='dibatalkan', cancel_requested=0 WHERE id=?");
                        psT.setInt(1, oid); psT.executeUpdate(); psT.close();
                    }
                    conn.commit();
                    flashMsg = "Pembatalan order #" + oid + " dikonfirmasi, stok dikembalikan.";
                } catch (Exception ex) {
                    conn.rollback();
                    flashMsg = "Gagal konfirmasi batal: " + ex.getMessage();
                } finally {
                    conn.setAutoCommit(true);
                }
            } else if ("reject_cancel".equals(action)) {
                PreparedStatement ps = conn.prepareStatement("UPDATE transaksi SET cancel_requested=0 WHERE id=?");
                ps.setInt(1, oid); ps.executeUpdate(); ps.close();
                flashMsg = "Permintaan pembatalan order #" + oid + " ditolak.";
            }
            conn.close();
        } catch (Exception e) {
            flashMsg = "Error: " + e.getMessage();
        }
    }

    // ---------- LOAD DATA ----------
    List<Map<String, Object>> orders = new ArrayList<>();
    Map<Integer, List<Map<String,Object>>> itemsByOrder = new HashMap<>();
    int countVerifikasi = 0, countBatal = 0;
    String errorMsg = "";

    try {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();
        DbInit.ensureSchema(conn);

        // Hitung badge notifikasi
        Statement stc = conn.createStatement();
        ResultSet rc1 = stc.executeQuery("SELECT COUNT(*) FROM transaksi WHERE metode_bayar='transfer' AND status_bayar='menunggu' AND bukti_transfer IS NOT NULL");
        if (rc1.next()) countVerifikasi = rc1.getInt(1); rc1.close();
        ResultSet rc2 = stc.executeQuery("SELECT COUNT(*) FROM transaksi WHERE cancel_requested=1");
        if (rc2.next()) countBatal = rc2.getInt(1); rc2.close();
        stc.close();

        // Pesanan yang pembayarannya belum terverifikasi TIDAK masuk ke area pemrosesan,
        // hanya tampil di filter "PERLU VERIFIKASI" / "MINTA BATAL".
        String where;
        if ("verifikasi".equals(curFilter)) where = "WHERE t.metode_bayar='transfer' AND t.status_bayar='menunggu' AND t.bukti_transfer IS NOT NULL ";
        else if ("batal".equals(curFilter)) where = "WHERE t.cancel_requested=1 ";
        else if ("dibatalkan".equals(curFilter)) where = "WHERE t.status='dibatalkan' ";
        else if (isValidStatus(curFilter)) where = "WHERE t.status = ? AND t.status_bayar='terverifikasi' ";
        else where = "WHERE t.status_bayar='terverifikasi' ";

        // Hitung total baris (1 baris per transaksi) untuk pagination
        PreparedStatement psCount = conn.prepareStatement("SELECT COUNT(*) FROM transaksi t " + where);
        if (where.contains("?")) psCount.setString(1, curFilter);
        ResultSet rsCount = psCount.executeQuery();
        if (rsCount.next()) totalRows = rsCount.getInt(1);
        rsCount.close(); psCount.close();

        totalPages = (int) Math.ceil(totalRows / (double) perPage);
        if (totalPages < 1) totalPages = 1;
        if (pageNum > totalPages) pageNum = totalPages;
        offset = (pageNum - 1) * perPage;

        String sql =
            "SELECT t.id, t.tanggal, t.total_pembayaran, t.status, t.metode_bayar, t.status_bayar, " +
            "t.bukti_transfer, t.ongkir, t.diskon, t.kode_voucher, t.cancel_requested, " +
            "u.nama_lengkap, sp.nama AS kirim_nama, COALESCE(SUM(d.qty),0) AS qty " +
            "FROM transaksi t " +
            "LEFT JOIN master_user u ON t.id_user = u.id " +
            "LEFT JOIN master_pengiriman sp ON t.metode_kirim = sp.kode " +
            "LEFT JOIN detail_transaksi d ON t.id = d.id_transaksi " +
            where +
            "GROUP BY t.id, t.tanggal, t.total_pembayaran, t.status, t.metode_bayar, t.status_bayar, " +
            "t.bukti_transfer, t.ongkir, t.diskon, t.kode_voucher, t.cancel_requested, u.nama_lengkap, sp.nama " +
            "ORDER BY t.tanggal DESC, t.id DESC LIMIT ? OFFSET ?";

        PreparedStatement ps = conn.prepareStatement(sql);
        int pi = 1;
        if (where.contains("?")) ps.setString(pi++, curFilter);
        ps.setInt(pi++, perPage);
        ps.setInt(pi++, offset);
        ResultSet rs = ps.executeQuery();
        StringBuilder ids = new StringBuilder();
        while (rs.next()) {
            Map<String, Object> o = new HashMap<>();
            int oid = rs.getInt("id");
            o.put("id", oid);
            o.put("tanggal",      rs.getString("tanggal"));
            o.put("total",        rs.getDouble("total_pembayaran"));
            o.put("status",       rs.getString("status"));
            o.put("metode_bayar", rs.getString("metode_bayar"));
            o.put("status_bayar", rs.getString("status_bayar"));
            o.put("bukti",        rs.getString("bukti_transfer"));
            o.put("ongkir",       rs.getDouble("ongkir"));
            o.put("diskon",       rs.getDouble("diskon"));
            o.put("voucher",      rs.getString("kode_voucher"));
            o.put("cancel_req",   rs.getInt("cancel_requested"));
            o.put("customer",     rs.getString("nama_lengkap") != null ? rs.getString("nama_lengkap") : "Guest");
            o.put("kirim_nama",   rs.getString("kirim_nama") != null ? rs.getString("kirim_nama") : "-");
            o.put("qty",          rs.getInt("qty"));
            orders.add(o);
            if (ids.length() > 0) ids.append(",");
            ids.append(oid);
        }
        rs.close(); ps.close();

        // Item per order
        if (ids.length() > 0) {
            Statement st2 = conn.createStatement();
            ResultSet rd = st2.executeQuery(
                "SELECT d.id_transaksi, d.qty, p.nama_produk FROM detail_transaksi d " +
                "JOIN master_product p ON d.id_product = p.id WHERE d.id_transaksi IN (" + ids + ")");
            while (rd.next()) {
                int oid = rd.getInt("id_transaksi");
                itemsByOrder.computeIfAbsent(oid, x -> new ArrayList<>());
                Map<String,Object> it = new HashMap<>();
                it.put("nama", rd.getString("nama_produk"));
                it.put("qty", rd.getInt("qty"));
                itemsByOrder.get(oid).add(it);
            }
            rd.close(); st2.close();
        }
        conn.close();
    } catch (Exception e) {
        errorMsg = e.getMessage();
    }

    String staffName = (String) session.getAttribute("nama_lengkap");

    // Helper link pagination & state untuk form aksi
    String filterParam = curFilter.isEmpty() ? "" : ("&filter=" + curFilter);
    String stateParams = filterParam + "&page=" + pageNum + "&per_page=" + perPage;
    String baseLink    = "pesanan.jsp?per_page=" + perPage + filterParam + "&page=";
    int fromRow = totalRows == 0 ? 0 : (offset + 1);
    int toRow   = Math.min(offset + perPage, totalRows);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Kelola Pesanan - VEND.IO Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background-color: #e5e7eb; }
        .brutal-shadow { box-shadow: 8px 8px 0px 0px rgba(0,0,0,1); }
        .brutal-btn { box-shadow: 4px 4px 0px 0px rgba(0,0,0,1); }
        .brutal-btn:active { box-shadow: 0px 0px 0px 0px rgba(0,0,0,1); transform: translate(4px, 4px); }
    </style>
</head>
<body class="flex min-h-screen">
    <!-- Sidebar -->
    <aside class="w-64 bg-black text-white flex flex-col justify-between py-6 flex-shrink-0">
        <div>
            <div class="px-6 flex items-center gap-3 mb-6">
                <div class="bg-[#FACC15] p-2">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                    </svg>
                </div>
                <h1 class="text-2xl font-[900] italic tracking-tighter">VEND.IO</h1>
            </div>
            <div class="border-t-[3px] border-white mx-6 mb-8"></div>
            <nav class="flex flex-col space-y-2">
                <a href="dashboard.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">Dashboard</a>
                <a href="pesanan.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase bg-[#FACC15] text-black">PESANAN</a>
                <a href="pengiriman.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">PENGIRIMAN</a>
                <a href="diskon.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">DISKON & PROMO</a>
                <a href="products.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">INVENTORY</a>
                <a href="kategori.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER KATEGORI</a>
                <a href="ukuran.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER UKURAN</a>
                <a href="users.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER USER</a>
                <a href="gudang.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER GUDANG</a>
                <a href="laporan.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">LAPORAN PENJUALAN</a>
            </nav>
        </div>
        <div class="px-6 mt-8">
            <div class="border-t-[3px] border-white mb-4"></div>
            <p class="text-xs font-bold text-gray-400 mb-1 tracking-widest uppercase">STAFF</p>
            <p class="font-[900] tracking-wider uppercase mb-2 truncate"><%= staffName %></p>
            <a href="logout.jsp" class="font-[900] text-red-500 hover:text-red-400 text-sm tracking-wider uppercase">LOG OUT</a>
        </div>
    </aside>

    <!-- Main -->
    <main class="flex-1 p-10 flex flex-col relative overflow-y-auto">
        <h2 class="text-4xl font-[900] text-black tracking-tight uppercase mb-8">KELOLA PESANAN</h2>

        <% if (!flashMsg.isEmpty()) { %>
        <div class="bg-[#4ADE80] border-[4px] border-black p-4 mb-6 brutal-shadow"><p class="font-[900] text-black uppercase m-0"><%= flashMsg %></p></div>
        <% } %>
        <% if (!errorMsg.isEmpty()) { %>
        <div class="bg-red-200 border-[4px] border-black p-4 mb-6 brutal-shadow"><p class="font-[900] text-black uppercase m-0">Error: <%= errorMsg %></p></div>
        <% } %>

        <!-- Filter -->
        <div class="flex flex-wrap gap-2 mb-6">
            <a href="pesanan.jsp" class="border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase tracking-wider brutal-btn <%= curFilter.isEmpty() ? "bg-black text-white" : "bg-white text-black" %>">SEMUA</a>
            <a href="pesanan.jsp?filter=verifikasi" class="border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase tracking-wider brutal-btn <%= "verifikasi".equals(curFilter) ? "bg-black text-white" : "bg-[#FACC15] text-black" %>">PERLU VERIFIKASI<% if (countVerifikasi>0) { %> (<%= countVerifikasi %>)<% } %></a>
            <a href="pesanan.jsp?filter=batal" class="border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase tracking-wider brutal-btn <%= "batal".equals(curFilter) ? "bg-black text-white" : "bg-orange-200 text-black" %>">MINTA BATAL<% if (countBatal>0) { %> (<%= countBatal %>)<% } %></a>
            <% for (int i = 0; i < FLOW.length; i++) { %>
            <a href="pesanan.jsp?filter=<%= FLOW[i] %>" class="border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase tracking-wider brutal-btn <%= curFilter.equals(FLOW[i]) ? "bg-black text-white" : "bg-white text-black" %>"><%= FLOW_LABEL[i] %></a>
            <% } %>
            <a href="pesanan.jsp?filter=dibatalkan" class="border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase tracking-wider brutal-btn <%= "dibatalkan".equals(curFilter) ? "bg-black text-white" : "bg-white text-black" %>">DIBATALKAN</a>
        </div>

        <!-- Info & jumlah per halaman -->
        <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
            <p class="font-bold text-xs text-gray-500 uppercase tracking-wider m-0">
                Menampilkan <%= fromRow %>&ndash;<%= toRow %> dari <%= totalRows %> pesanan
                <% if (totalRows > 0) { %><span class="text-gray-300">&middot;</span> Hal. <%= pageNum %>/<%= totalPages %><% } %>
            </p>
            <div class="flex items-center gap-2">
                <span class="font-[900] text-xs uppercase tracking-wider">Per halaman</span>
                <select onchange="location.href='pesanan.jsp?per_page=' + this.value + '&page=1<%= filterParam %>'"
                        class="border-[3px] border-black px-3 py-2 font-[900] text-xs uppercase focus:outline-none brutal-btn bg-white cursor-pointer">
                    <option value="5"  <%= perPage==5  ? "selected" : "" %>>5</option>
                    <option value="10" <%= perPage==10 ? "selected" : "" %>>10</option>
                    <option value="25" <%= perPage==25 ? "selected" : "" %>>25</option>
                </select>
            </div>
        </div>

        <% if (orders.isEmpty()) { %>
        <div class="bg-white border-[4px] border-black p-16 brutal-shadow text-center">
            <p class="font-[900] text-2xl uppercase text-gray-300 m-0">TIDAK ADA PESANAN</p>
        </div>
        <% } else { %>

        <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
            <% for (Map<String, Object> o : orders) {
                int oid = (Integer) o.get("id");
                String status = (String) o.get("status");
                String metodeBayar = (String) o.get("metode_bayar");
                String statusBayar = (String) o.get("status_bayar");
                String bukti = (String) o.get("bukti");
                int cancelReq = (Integer) o.get("cancel_req");
                String voucher = (String) o.get("voucher");
                boolean isTransfer = "transfer".equalsIgnoreCase(metodeBayar);
                boolean bayarMenunggu = "menunggu".equalsIgnoreCase(statusBayar);
                boolean dibatalkan = "dibatalkan".equalsIgnoreCase(status);
                List<Map<String,Object>> its = itemsByOrder.get(oid);
            %>
            <div class="bg-black p-3 brutal-shadow">
                <div class="bg-white border-[4px] border-black p-5">

                    <!-- header -->
                    <div class="flex items-center justify-between flex-wrap gap-2 mb-3">
                        <div class="flex items-center gap-2">
                            <span class="bg-[#FACC15] border-[2px] border-black px-2 py-0.5 font-[900] text-xs">#<%= oid %></span>
                            <span class="font-[900] text-sm uppercase"><%= o.get("customer") %></span>
                        </div>
                        <span class="border-[2px] border-black px-2 py-0.5 font-[900] text-[10px] uppercase <%= statusBadge(status) %>"><%= status %></span>
                    </div>
                    <p class="font-bold text-gray-400 text-xs m-0 mb-3"><%= o.get("tanggal") %></p>

                    <!-- items -->
                    <div class="border-[2px] border-gray-200 p-2 mb-3 text-xs">
                        <% if (its != null) for (Map<String,Object> it : its) { %>
                        <div class="flex justify-between"><span class="font-bold text-gray-600 uppercase truncate mr-2"><%= it.get("nama") %></span><span class="font-[900] whitespace-nowrap"><%= it.get("qty") %> pcs</span></div>
                        <% } %>
                    </div>

                    <!-- info grid -->
                    <div class="grid grid-cols-2 gap-3 mb-3 text-xs">
                        <div>
                            <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0">PAYMENT</p>
                            <p class="font-[900] uppercase m-0"><%= isTransfer ? "Transfer" : "E-Wallet" %></p>
                            <span class="inline-block mt-1 border-[2px] border-black px-2 py-0.5 font-[900] text-[10px] uppercase <%= bayarBadge(statusBayar) %>"><%= statusBayar %></span>
                            <% if (bukti != null && !bukti.isEmpty()) { %>
                            <a href="../<%= bukti %>" target="_blank" class="block mt-1 text-[10px] font-[900] uppercase text-[#3498DB] underline">Lihat Bukti Transfer</a>
                            <% } %>
                        </div>
                        <div>
                            <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0">SHIPPING</p>
                            <p class="font-[900] uppercase m-0"><%= o.get("kirim_nama") %></p>
                            <p class="text-gray-500 m-0 mt-1">Ongkir Rp<%= String.format("%,.0f", (Double) o.get("ongkir")) %></p>
                            <% if ((Double) o.get("diskon") > 0) { %><p class="text-green-600 font-[900] m-0">Diskon Rp<%= String.format("%,.0f", (Double) o.get("diskon")) %><%= voucher != null ? (" ("+voucher+")") : "" %></p><% } %>
                        </div>
                    </div>

                    <div class="flex justify-between items-center border-t-[2px] border-black pt-2 mb-3">
                        <span class="font-[900] uppercase text-xs">TOTAL</span>
                        <span class="font-[900] text-xl">Rp<%= String.format("%,.0f", (Double) o.get("total")) %></span>
                    </div>

                    <!-- ACTION: verifikasi pembayaran transfer -->
                    <% if (isTransfer && bayarMenunggu && !dibatalkan) { %>
                    <div class="border-[2px] border-black bg-[#FACC15] p-2 mb-2">
                        <p class="font-[900] text-[10px] uppercase m-0 mb-2"><%= (bukti != null && !bukti.isEmpty()) ? "Verifikasi pembayaran:" : "Menunggu customer upload bukti" %></p>
                        <% if (bukti != null && !bukti.isEmpty()) { %>
                        <div class="flex gap-2">
                            <form action="pesanan.jsp?action=verify_payment<%= stateParams %>" method="POST" class="flex-1">
                                <input type="hidden" name="id" value="<%= oid %>">
                                <button class="w-full bg-[#4ADE80] border-[2px] border-black px-2 py-1 font-[900] text-[10px] uppercase hover:bg-green-400">✓ VERIFIKASI</button>
                            </form>
                            <form action="pesanan.jsp?action=reject_payment<%= stateParams %>" method="POST" class="flex-1">
                                <input type="hidden" name="id" value="<%= oid %>">
                                <button class="w-full bg-red-400 border-[2px] border-black px-2 py-1 font-[900] text-[10px] uppercase hover:bg-red-500">✕ TOLAK</button>
                            </form>
                        </div>
                        <% } %>
                    </div>
                    <% } %>

                    <!-- ACTION: konfirmasi pembatalan -->
                    <% if (cancelReq == 1 && !dibatalkan) { %>
                    <div class="border-[2px] border-black bg-orange-200 p-2 mb-2">
                        <p class="font-[900] text-[10px] uppercase m-0 mb-2">Customer minta batal:</p>
                        <div class="flex gap-2">
                            <form action="pesanan.jsp?action=confirm_cancel<%= stateParams %>" method="POST" class="flex-1" onsubmit="return confirm('Konfirmasi pembatalan? Stok akan dikembalikan.');">
                                <input type="hidden" name="id" value="<%= oid %>">
                                <button class="w-full bg-red-400 border-[2px] border-black px-2 py-1 font-[900] text-[10px] uppercase hover:bg-red-500">KONFIRMASI BATAL</button>
                            </form>
                            <form action="pesanan.jsp?action=reject_cancel<%= stateParams %>" method="POST" class="flex-1">
                                <input type="hidden" name="id" value="<%= oid %>">
                                <button class="w-full bg-white border-[2px] border-black px-2 py-1 font-[900] text-[10px] uppercase hover:bg-gray-100">TOLAK BATAL</button>
                            </form>
                        </div>
                    </div>
                    <% } %>

                    <!-- ACTION: ubah status -->
                    <% if (!dibatalkan) { %>
                    <form action="pesanan.jsp?action=update_status<%= stateParams %>" method="POST" class="flex items-center gap-2">
                        <input type="hidden" name="id" value="<%= oid %>">
                        <select name="status" class="flex-1 border-[2px] border-black p-1 font-[900] text-xs uppercase focus:outline-none">
                            <% for (int i = 0; i < FLOW.length; i++) { %>
                            <option value="<%= FLOW[i] %>" <%= FLOW[i].equalsIgnoreCase(status) ? "selected" : "" %>><%= FLOW_LABEL[i] %></option>
                            <% } %>
                        </select>
                        <button class="bg-black text-white border-[2px] border-black px-4 py-1 font-[900] text-xs uppercase hover:bg-gray-800">SAVE</button>
                    </form>
                    <% } %>

                </div>
            </div>
            <% } %>
        </div>

        <!-- Pagination controls -->
        <% if (totalPages > 1) { %>
        <div class="flex flex-wrap items-center justify-center gap-2 mt-8">
            <a href="<%= pageNum > 1 ? (baseLink + (pageNum-1)) : "javascript:void(0)" %>"
               class="border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase tracking-wider brutal-btn bg-white text-black <%= pageNum <= 1 ? "opacity-40 pointer-events-none" : "hover:bg-gray-100" %>">&larr; PREV</a>

            <%
                int startP = Math.max(1, pageNum - 2);
                int endP   = Math.min(totalPages, pageNum + 2);
                if (startP > 1) {
            %>
            <a href="<%= baseLink + 1 %>" class="border-[3px] border-black w-10 h-10 flex items-center justify-center font-[900] text-xs brutal-btn bg-white text-black hover:bg-gray-100">1</a>
            <% if (startP > 2) { %><span class="font-[900] px-1 text-gray-400">&hellip;</span><% } %>
            <% }
                for (int p = startP; p <= endP; p++) { %>
            <a href="<%= baseLink + p %>" class="border-[3px] border-black w-10 h-10 flex items-center justify-center font-[900] text-xs brutal-btn <%= p == pageNum ? "bg-black text-white" : "bg-white text-black hover:bg-gray-100" %>"><%= p %></a>
            <% }
                if (endP < totalPages) {
                    if (endP < totalPages - 1) { %><span class="font-[900] px-1 text-gray-400">&hellip;</span><% }
            %>
            <a href="<%= baseLink + totalPages %>" class="border-[3px] border-black w-10 h-10 flex items-center justify-center font-[900] text-xs brutal-btn bg-white text-black hover:bg-gray-100"><%= totalPages %></a>
            <% } %>

            <a href="<%= pageNum < totalPages ? (baseLink + (pageNum+1)) : "javascript:void(0)" %>"
               class="border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase tracking-wider brutal-btn bg-white text-black <%= pageNum >= totalPages ? "opacity-40 pointer-events-none" : "hover:bg-gray-100" %>">NEXT &rarr;</a>
        </div>
        <% } %>

        <% } %>

        <p class="mt-6 font-bold text-gray-400 text-sm text-right">Developed by Dandy & Verly</p>
    </main>
</body>
</html>
