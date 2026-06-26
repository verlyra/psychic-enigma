<%@page import="jdbc.koneksi"%>
<%@page import="jdbc.DbInit"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    static final String[] FLOW       = {"pending", "diproses", "dipacking", "dikirim", "selesai"};
    static final String[] FLOW_LABEL = {"Pending", "Diproses", "Dipacking", "Dikirim", "Selesai"};

    int statusIndex(String s) {
        if (s == null) return 0;
        for (int i = 0; i < FLOW.length; i++) if (FLOW[i].equalsIgnoreCase(s.trim())) return i;
        return 0;
    }
    String statusLabel(String s) {
        if (s != null && "dibatalkan".equalsIgnoreCase(s.trim())) return "Dibatalkan";
        return FLOW_LABEL[statusIndex(s)];
    }
    String badgeClass(String s) {
        switch (s == null ? "pending" : s.trim().toLowerCase()) {
            case "diproses":   return "bg-[#3498DB] text-white";
            case "dipacking":  return "bg-[#A855F7] text-white";
            case "dikirim":    return "bg-[#FB923C] text-black";
            case "selesai":    return "bg-[#4ADE80] text-black";
            case "dibatalkan": return "bg-red-400 text-black";
            default:           return "bg-gray-300 text-black";
        }
    }
    // status bisa diminta batal hanya sebelum dikirim
    boolean bisaBatal(String status, int cancelReq) {
        if (status == null) return false;
        String s = status.trim().toLowerCase();
        return cancelReq == 0 && (s.equals("pending") || s.equals("diproses") || s.equals("dipacking"));
    }
%>
<%
    if (session.getAttribute("user_id") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String userName = (String) session.getAttribute("nama_lengkap");
    int    userId   = Integer.parseInt((String) session.getAttribute("user_id"));

    // ---- Aksi: permintaan pembatalan ----
    String action = request.getParameter("action");
    String curFilter = request.getParameter("filter");
    if (curFilter == null) curFilter = "";

    if ("request_cancel".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        String idStr = request.getParameter("id");
        if (idStr != null) {
            try {
                int oid = Integer.parseInt(idStr);
                koneksi k = new koneksi();
                Connection conn = k.bukaKoneksi();
                DbInit.ensureSchema(conn);
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE transaksi SET cancel_requested = 1 " +
                    "WHERE id = ? AND id_user = ? AND cancel_requested = 0 " +
                    "AND status IN ('pending','diproses','dipacking')");
                ps.setInt(1, oid);
                ps.setInt(2, userId);
                ps.executeUpdate();
                ps.close(); conn.close();
            } catch (Exception ignored) {}
        }
        String fParam = curFilter.isEmpty() ? "" : ("&filter=" + curFilter);
        response.sendRedirect("order_history.jsp?cancel=requested" + fParam);
        return;
    }

    String uploadFlag = request.getParameter("upload");
    String cancelFlag = request.getParameter("cancel");

    // ---- Hitung jumlah pesanan per status (untuk badge filter) ----
    java.util.Map<String,Integer> statusCounts = new java.util.LinkedHashMap<>();
    statusCounts.put("", 0);           // semua
    for (String f : FLOW) statusCounts.put(f, 0);
    statusCounts.put("dibatalkan", 0);

    try {
        koneksi kc = new koneksi();
        Connection connC = kc.bukaKoneksi();
        PreparedStatement psC = connC.prepareStatement(
            "SELECT status, COUNT(*) AS cnt FROM transaksi WHERE id_user = ? GROUP BY status");
        psC.setInt(1, userId);
        ResultSet rsC = psC.executeQuery();
        int total = 0;
        while (rsC.next()) {
            String st = rsC.getString("status");
            int cnt = rsC.getInt("cnt");
            total += cnt;
            if (statusCounts.containsKey(st)) statusCounts.put(st, cnt);
        }
        statusCounts.put("", total);
        rsC.close(); psC.close(); connC.close();
    } catch (Exception ignored) {}

    List<Map<String, Object>> orders = new ArrayList<>();
    String errorMsg = "";

    try {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();
        DbInit.ensureSchema(conn);

        // Bangun WHERE clause berdasarkan filter
        String whereClause;
        if ("dibatalkan".equals(curFilter)) {
            whereClause = "AND t.status = 'dibatalkan' ";
        } else if (!curFilter.isEmpty()) {
            whereClause = "AND t.status = ? ";
        } else {
            whereClause = "";
        }

        PreparedStatement psTrx = conn.prepareStatement(
            "SELECT t.id, t.tanggal, t.total_pembayaran, t.status, t.metode_bayar, t.status_bayar, " +
            "t.bukti_transfer, t.ongkir, t.diskon, t.cancel_requested, sp.nama AS kirim_nama " +
            "FROM transaksi t LEFT JOIN master_pengiriman sp ON t.metode_kirim = sp.kode " +
            "WHERE t.id_user = ? " + whereClause + "ORDER BY t.tanggal DESC, t.id DESC");
        psTrx.setInt(1, userId);
        if (!curFilter.isEmpty() && !"dibatalkan".equals(curFilter)) {
            psTrx.setString(2, curFilter);
        }
        ResultSet rsTrx = psTrx.executeQuery();

        Map<Integer, Map<String, Object>> orderById = new LinkedHashMap<>();
        while (rsTrx.next()) {
            Map<String, Object> o = new HashMap<>();
            int oid = rsTrx.getInt("id");
            o.put("id",            oid);
            o.put("tanggal",       rsTrx.getString("tanggal"));
            o.put("total",         rsTrx.getDouble("total_pembayaran"));
            o.put("status",        rsTrx.getString("status"));
            o.put("metode_bayar",  rsTrx.getString("metode_bayar"));
            o.put("status_bayar",  rsTrx.getString("status_bayar"));
            o.put("bukti",         rsTrx.getString("bukti_transfer"));
            o.put("ongkir",        rsTrx.getDouble("ongkir"));
            o.put("diskon",        rsTrx.getDouble("diskon"));
            o.put("cancel_req",    rsTrx.getInt("cancel_requested"));
            o.put("kirim_nama",    rsTrx.getString("kirim_nama") != null ? rsTrx.getString("kirim_nama") : "-");
            o.put("items",         new ArrayList<Map<String, Object>>());
            orderById.put(oid, o);
            orders.add(o);
        }
        rsTrx.close(); psTrx.close();

        if (!orderById.isEmpty()) {
            PreparedStatement psDet = conn.prepareStatement(
                "SELECT d.id_transaksi, d.qty, d.harga_jual, d.subtotal, p.nama_produk, p.image_url " +
                "FROM detail_transaksi d JOIN master_product p ON d.id_product = p.id " +
                "WHERE d.id_transaksi IN (SELECT id FROM transaksi WHERE id_user = ?)");
            psDet.setInt(1, userId);
            ResultSet rsDet = psDet.executeQuery();
            while (rsDet.next()) {
                int oid = rsDet.getInt("id_transaksi");
                Map<String, Object> o = orderById.get(oid);
                if (o == null) continue;
                String img = rsDet.getString("image_url");
                if (img == null || img.trim().isEmpty()) img = "https://via.placeholder.com/64/ffffff/000000?text=IMG";
                Map<String, Object> item = new HashMap<>();
                item.put("nama",     rsDet.getString("nama_produk"));
                item.put("image",    img);
                item.put("qty",      rsDet.getInt("qty"));
                item.put("harga",    rsDet.getDouble("harga_jual"));
                item.put("subtotal", rsDet.getDouble("subtotal"));
                ((List<Map<String, Object>>) o.get("items")).add(item);
            }
            rsDet.close(); psDet.close();
        }
        conn.close();
    } catch (Exception e) {
        errorMsg = e.getMessage();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VEND.IO - Order History</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background-color: #e5e7eb; }
        .brutal-shadow { box-shadow: 8px 8px 0px 0px rgba(0,0,0,1); }
        .brutal-btn { box-shadow: 4px 4px 0px 0px rgba(0,0,0,1); }
        .brutal-btn:active { box-shadow: 0px 0px 0px 0px rgba(0,0,0,1); transform: translate(4px, 4px); }
        a { text-decoration: none; }
    </style>
</head>
<body class="min-h-screen">

    <!-- Header -->
    <header class="bg-[#FACC15] border-b-[4px] border-black sticky top-0 z-50">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-20">
                <div class="flex items-center gap-3">
                    <div class="bg-white border-[3px] border-black p-2 brutal-btn">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                        </svg>
                    </div>
                    <a href="index.jsp"><h1 class="text-3xl font-[900] italic tracking-tighter text-black m-0">VEND.IO</h1></a>
                </div>
                <div class="flex items-center gap-4">
                    <div class="text-right hidden md:block">
                        <p class="text-xs font-[900] text-black tracking-widest uppercase m-0">HELLO,</p>
                        <p class="text-lg font-[900] text-black uppercase m-0"><%= userName %></p>
                    </div>
                    <a href="index.jsp" class="bg-white border-[3px] border-black px-4 py-2 font-[900] text-black tracking-widest uppercase brutal-btn hover:bg-gray-100 transition-colors">← SHOP</a>
                    <a href="logout.jsp" class="bg-white border-[3px] border-black p-2 brutal-btn hover:bg-red-500 hover:text-white transition-colors" title="Logout">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                    </a>
                </div>
            </div>
        </div>
    </header>

    <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h2 class="text-4xl font-[900] text-black uppercase mb-8 inline-block bg-white border-[4px] border-black px-4 py-2 brutal-btn">
            ORDER HISTORY
        </h2>

        <% if ("ok".equals(uploadFlag)) { %>
        <div class="bg-[#4ADE80] border-[4px] border-black p-4 mb-6 brutal-shadow"><p class="font-[900] text-black uppercase m-0">Bukti transfer berhasil diupload. Menunggu verifikasi admin.</p></div>
        <% } else if (uploadFlag != null) { %>
        <div class="bg-red-200 border-[4px] border-black p-4 mb-6 brutal-shadow"><p class="font-[900] text-black uppercase m-0">Upload bukti gagal. Coba lagi.</p></div>
        <% } %>
        <% if ("requested".equals(cancelFlag)) { %>
        <div class="bg-[#FACC15] border-[4px] border-black p-4 mb-6 brutal-shadow"><p class="font-[900] text-black uppercase m-0">Permintaan pembatalan dikirim. Menunggu konfirmasi admin.</p></div>
        <% } %>
        <% if (!errorMsg.isEmpty()) { %>
        <div class="bg-red-200 border-[4px] border-black p-4 mb-6 brutal-shadow"><p class="font-[900] text-black uppercase m-0">Error: <%= errorMsg %></p></div>
        <% } %>

        <!-- Filter Tabs -->
        <div class="flex flex-wrap gap-2 mb-6">
            <%
                String[][] filterDefs = {
                    {"",           "SEMUA",     "bg-black text-white",     "bg-white text-black"},
                    {"pending",    "PENDING",   "bg-black text-white",     "bg-white text-black"},
                    {"diproses",   "DIPROSES",  "bg-[#3498DB] text-white", "bg-white text-black"},
                    {"dipacking",  "DIKEMAS",   "bg-[#A855F7] text-white", "bg-white text-black"},
                    {"dikirim",    "DIKIRIM",   "bg-[#FB923C] text-black", "bg-white text-black"},
                    {"selesai",    "SELESAI",   "bg-[#4ADE80] text-black", "bg-white text-black"},
                    {"dibatalkan", "DIBATALKAN","bg-red-400 text-black",   "bg-white text-black"},
                };
                for (String[] fd : filterDefs) {
                    String fKey    = fd[0];
                    String fLabel  = fd[1];
                    String activeC = fd[2];
                    String inactC  = fd[3];
                    boolean isActive = curFilter.equals(fKey);
                    int cnt = statusCounts.getOrDefault(fKey, 0);
            %>
            <a href="order_history.jsp<%= fKey.isEmpty() ? "" : ("?filter=" + fKey) %>"
               class="border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase tracking-wider brutal-btn <%= isActive ? activeC : inactC %> hover:opacity-80 transition-opacity flex items-center gap-1">
                <%= fLabel %>
                <% if (cnt > 0) { %>
                <span class="inline-flex items-center justify-center w-5 h-5 rounded-full text-[10px] font-[900]
                    <%= isActive ? "bg-white text-black" : "bg-black text-white" %>"><%= cnt %></span>
                <% } %>
            </a>
            <% } %>
        </div>

        <% if (orders.isEmpty()) { %>
        <div class="bg-white border-[4px] border-black p-16 brutal-shadow text-center">
            <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mx-auto mb-6 opacity-20">
                <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path><line x1="3" y1="6" x2="21" y2="6"></line><path d="M16 10a4 4 0 0 1-8 0"></path>
            </svg>
            <p class="font-[900] text-3xl uppercase text-black mb-6">NO ORDERS YET</p>
            <a href="index.jsp" class="bg-[#FACC15] border-[4px] border-black px-8 py-3 font-[900] text-black tracking-widest uppercase brutal-btn hover:bg-yellow-400 transition-colors inline-block">START SHOPPING</a>
        </div>
        <% } else { %>

        <div class="space-y-6">
            <% for (Map<String, Object> o : orders) {
                String status      = (String) o.get("status");
                String metodeBayar = (String) o.get("metode_bayar");
                String statusBayar = (String) o.get("status_bayar");
                String bukti       = (String) o.get("bukti");
                int    cancelReq   = (Integer) o.get("cancel_req");
                int    curIdx      = statusIndex(status);
                boolean dibatalkan = status != null && "dibatalkan".equalsIgnoreCase(status.trim());
                boolean isTransfer = "transfer".equalsIgnoreCase(metodeBayar);
                boolean bayarVerif = "terverifikasi".equalsIgnoreCase(statusBayar);
                boolean bayarTolak = "ditolak".equalsIgnoreCase(statusBayar);
                List<Map<String, Object>> items = (List<Map<String, Object>>) o.get("items");

                String bayarBadge, bayarLabel;
                if (bayarVerif) { bayarBadge = "bg-[#4ADE80] text-black"; bayarLabel = "Lunas / Terverifikasi"; }
                else if (bayarTolak) { bayarBadge = "bg-red-400 text-black"; bayarLabel = "Pembayaran Ditolak"; }
                else { bayarBadge = "bg-gray-300 text-black"; bayarLabel = "Menunggu Pembayaran"; }
            %>
            <div class="bg-black p-3 brutal-shadow">
                <div class="bg-white border-[4px] border-black">

                    <!-- Header -->
                    <div class="px-6 py-4 border-b-[3px] border-black flex flex-wrap items-center justify-between gap-3">
                        <div>
                            <span class="bg-[#FACC15] border-[2px] border-black px-3 py-1 font-[900] text-xs uppercase">ORDER #<%= o.get("id") %></span>
                            <p class="font-bold text-gray-500 text-xs mt-2 m-0"><%= o.get("tanggal") %></p>
                        </div>
                        <span class="border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase tracking-widest brutal-btn <%= badgeClass(status) %>">
                            <%= statusLabel(status) %>
                        </span>
                    </div>

                    <!-- Progress / cancelled banner -->
                    <% if (dibatalkan) { %>
                    <div class="px-6 py-5 border-b-[2px] border-gray-100 bg-red-50">
                        <% if (bayarTolak) { %>
                        <p class="font-[900] uppercase text-red-600 m-0 mb-1 flex items-center gap-2">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
                            PEMBAYARAN DITOLAK ADMIN
                        </p>
                        <p class="text-sm font-bold text-red-500 m-0">Bukti transfer yang kamu upload tidak valid atau tidak sesuai. Pesanan otomatis dibatalkan dan stok dikembalikan.</p>
                        <% } else { %>
                        <p class="font-[900] uppercase text-red-500 m-0 flex items-center gap-2">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
                            PESANAN DIBATALKAN
                        </p>
                        <% } %>
                    </div>
                    <% } else { %>
                    <div class="px-6 py-6 border-b-[2px] border-gray-100">
                        <div class="flex items-center">
                            <% for (int i = 0; i < FLOW.length; i++) { boolean done = i <= curIdx; %>
                            <div class="flex flex-col items-center flex-shrink-0">
                                <div class="w-8 h-8 border-[3px] border-black flex items-center justify-center font-[900] text-xs <%= done ? "bg-[#4ADE80] text-black" : "bg-white text-gray-300" %>">
                                    <% if (done) { %>&#10003;<% } else { %><%= i + 1 %><% } %>
                                </div>
                                <span class="text-[10px] font-[900] uppercase tracking-wide mt-1 <%= done ? "text-black" : "text-gray-300" %>"><%= FLOW_LABEL[i] %></span>
                            </div>
                            <% if (i < FLOW.length - 1) { %>
                            <div class="flex-1 h-[3px] mx-1 mb-4 <%= (i < curIdx) ? "bg-black" : "bg-gray-200" %>"></div>
                            <% } } %>
                        </div>
                    </div>
                    <% } %>

                    <!-- Payment + shipping info -->
                    <div class="px-6 py-4 border-b-[2px] border-gray-100 grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">PAYMENT</p>
                            <p class="font-[900] text-sm uppercase m-0 mb-1"><%= "ewallet".equalsIgnoreCase(metodeBayar) ? "E-Wallet" : "Transfer Bank" %></p>
                            <span class="inline-block border-[2px] border-black px-2 py-0.5 font-[900] text-[10px] uppercase <%= bayarBadge %>"><%= bayarLabel %></span>
                            <% if (bukti != null && !bukti.isEmpty()) { %>
                            <a href="<%= bukti %>" target="_blank" class="inline-block ml-1 text-[10px] font-[900] uppercase text-[#3498DB] underline">Lihat Bukti</a>
                            <% } %>
                        </div>
                        <div>
                            <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">SHIPPING</p>
                            <p class="font-[900] text-sm uppercase m-0"><%= o.get("kirim_nama") %></p>
                        </div>
                    </div>

                    <!-- Upload bukti transfer (transfer & belum lunas) -->
                    <% if (isTransfer && !bayarVerif && (bukti == null || bukti.isEmpty() || bayarTolak)) { %>
                    <div class="px-6 py-4 border-b-[2px] border-gray-100 bg-[#FACC15]/20">
                        <p class="font-[900] text-xs uppercase mb-2 m-0"><%= bayarTolak ? "Bukti ditolak — upload ulang" : "Upload bukti transfer" %></p>
                        <form action="UploadBukti" method="POST" enctype="multipart/form-data" class="flex flex-col sm:flex-row gap-2">
                            <input type="hidden" name="order_id" value="<%= o.get("id") %>">
                            <input type="file" name="bukti" accept="image/*" required class="flex-1 border-[3px] border-black p-2 font-bold text-black bg-white text-sm focus:outline-none">
                            <button type="submit" class="bg-black text-white border-[3px] border-black px-4 py-2 font-[900] uppercase text-xs tracking-widest brutal-btn hover:bg-gray-800 transition-colors whitespace-nowrap">UPLOAD</button>
                        </form>
                    </div>
                    <% } %>

                    <!-- Items -->
                    <div class="divide-y-[2px] divide-gray-100">
                        <% for (Map<String, Object> item : items) { %>
                        <div class="flex items-center gap-4 p-4">
                            <div class="w-12 h-12 border-[3px] border-black overflow-hidden flex-shrink-0">
                                <img src="<%= item.get("image") %>" alt="<%= item.get("nama") %>" class="w-full h-full object-cover">
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="font-[900] text-black uppercase text-sm m-0 truncate"><%= item.get("nama") %></p>
                                <p class="font-bold text-gray-500 text-xs m-0"><%= item.get("qty") %> &times; Rp<%= String.format("%,.0f", (Double) item.get("harga")) %></p>
                            </div>
                            <p class="font-[900] text-black whitespace-nowrap text-sm">Rp<%= String.format("%,.0f", (Double) item.get("subtotal")) %></p>
                        </div>
                        <% } %>
                    </div>

                    <!-- Totals + actions -->
                    <div class="px-6 py-4 border-t-[2px] border-gray-100 space-y-1">
                        <% if ((Double) o.get("diskon") > 0) { %>
                        <div class="flex justify-between text-xs"><span class="font-bold text-gray-400 uppercase">Diskon</span><span class="font-[900] text-green-600">− Rp<%= String.format("%,.0f", (Double) o.get("diskon")) %></span></div>
                        <% } %>
                        <div class="flex justify-between text-xs"><span class="font-bold text-gray-400 uppercase">Ongkir</span><span class="font-bold">Rp<%= String.format("%,.0f", (Double) o.get("ongkir")) %></span></div>
                    </div>
                    <div class="px-6 py-4 border-t-[3px] border-black bg-gray-50 flex flex-wrap justify-between items-center gap-3">
                        <div class="flex items-center gap-3">
                            <span class="font-[900] uppercase text-sm tracking-wider">TOTAL</span>
                            <span class="font-[900] text-2xl">Rp<%= String.format("%,.0f", (Double) o.get("total")) %></span>
                        </div>
                        <div>
                            <% if (dibatalkan) { %>
                            <!-- tidak ada aksi -->
                            <% } else if (cancelReq == 1) { %>
                            <span class="border-[3px] border-black bg-orange-200 px-4 py-2 font-[900] text-xs uppercase tracking-wide">Menunggu Konfirmasi Pembatalan</span>
                            <% } else if (bisaBatal(status, cancelReq)) { %>
                            <form action="order_history.jsp?action=request_cancel<%= curFilter.isEmpty() ? "" : ("&filter=" + curFilter) %>" method="POST" onsubmit="return confirm('Ajukan pembatalan pesanan ini?');">
                                <input type="hidden" name="id" value="<%= o.get("id") %>">
                                <button type="submit" class="border-[3px] border-black bg-white px-4 py-2 font-[900] text-xs uppercase tracking-wide text-red-500 brutal-btn hover:bg-red-50 transition-colors">Batalkan Pesanan</button>
                            </form>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
        </div>

        <% } %>

        <div class="text-center mt-12 pb-10">
            <p class="font-bold text-gray-400 text-sm m-0">Developed by Dandy & Verly</p>
        </div>
    </main>

</body>
</html>
