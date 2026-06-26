<%@page import="jdbc.koneksi"%>
<%@page import="jdbc.DbInit"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    // Hitung nilai potongan dari sebuah diskon terhadap subtotal produk
    double hitungPotongan(String jenis, double nilai, double maks, double subtotal) {
        double pot;
        if ("persen".equalsIgnoreCase(jenis)) {
            pot = subtotal * nilai / 100.0;
            if (maks > 0 && pot > maks) pot = maks;
        } else {
            pot = nilai;
        }
        if (pot > subtotal) pot = subtotal;
        if (pot < 0) pot = 0;
        return pot;
    }
%>
<%
    if (session.getAttribute("user_id") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Map<String, Integer> cart = (Map<String, Integer>) session.getAttribute("cart");
    if (cart == null || cart.isEmpty()) {
        response.sendRedirect("index.jsp");
        return;
    }

    String userName = (String) session.getAttribute("nama_lengkap");
    int userId = Integer.parseInt((String) session.getAttribute("user_id"));

    // Profil user untuk info pengiriman
    String userPhone = "-";
    String userAddress = "-";
    try {
        koneksi ku = new koneksi();
        Connection connU = ku.bukaKoneksi();
        PreparedStatement psU = connU.prepareStatement("SELECT no_telp, alamat FROM master_user WHERE id = ?");
        psU.setInt(1, userId);
        ResultSet rsU = psU.executeQuery();
        if (rsU.next()) {
            userPhone   = rsU.getString("no_telp")  != null ? rsU.getString("no_telp")  : "-";
            userAddress = rsU.getString("alamat")    != null ? rsU.getString("alamat")    : "-";
        }
        rsU.close(); psU.close(); connU.close();
    } catch (Exception ignored) {}

    // Muat isi keranjang dari DB
    List<Map<String, Object>> cartItems = new ArrayList<>();
    double subtotalProduk = 0;
    try {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();
        DbInit.ensureSchema(conn);
        for (Map.Entry<String, Integer> entry : cart.entrySet()) {
            try {
                int pid = Integer.parseInt(entry.getKey());
                int qty = entry.getValue();
                PreparedStatement ps = conn.prepareStatement("SELECT * FROM master_product WHERE id = ?");
                ps.setInt(1, pid);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    Map<String, Object> item = new HashMap<>();
                    int stok = rs.getInt("stok");
                    if (qty > stok) qty = stok;
                    String img = rs.getString("image_url");
                    if (img == null || img.trim().isEmpty()) img = "https://via.placeholder.com/64/ffffff/000000?text=IMG";
                    item.put("id",         rs.getInt("id"));
                    item.put("nama",       rs.getString("nama_produk"));
                    item.put("image",      img);
                    item.put("harga_jual", rs.getDouble("harga_jual"));
                    item.put("harga_beli", rs.getDouble("harga_beli"));
                    item.put("stok",       stok);
                    item.put("qty",        qty);
                    double subtotal = rs.getDouble("harga_jual") * qty;
                    item.put("subtotal", subtotal);
                    subtotalProduk += subtotal;
                    cartItems.add(item);
                }
                rs.close(); ps.close();
            } catch (Exception ignored) {}
        }
        conn.close();
    } catch (Exception ignored) {}

    // ---- Opsi pengiriman dari DB ----
    List<Map<String, Object>> shipOpts = new ArrayList<>();
    try {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();
        PreparedStatement ps = conn.prepareStatement(
            "SELECT kode, nama, biaya, estimasi FROM master_pengiriman WHERE aktif = 1 ORDER BY biaya DESC");
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            Map<String, Object> m = new HashMap<>();
            m.put("kode",     rs.getString("kode"));
            m.put("nama",     rs.getString("nama"));
            m.put("biaya",    rs.getDouble("biaya"));
            m.put("estimasi", rs.getString("estimasi") != null ? rs.getString("estimasi") : "");
            shipOpts.add(m);
        }
        rs.close(); ps.close(); conn.close();
    } catch (Exception ignored) {}

    // ---- Parameter pilihan user ----
    String metodeBayar = request.getParameter("metode_bayar");
    if (!"ewallet".equals(metodeBayar)) metodeBayar = "transfer";

    String metodeKirim = request.getParameter("metode_kirim");
    String voucherInput = request.getParameter("kode_voucher");
    if (voucherInput == null) voucherInput = "";
    voucherInput = voucherInput.trim();

    // Tentukan ongkir dari opsi terpilih
    double ongkir = 0;
    String kirimNama = "";
    Map<String, Object> selShip = null;
    for (Map<String, Object> m : shipOpts) {
        if (m.get("kode").equals(metodeKirim)) { selShip = m; break; }
    }
    if (selShip == null && !shipOpts.isEmpty()) { selShip = shipOpts.get(0); }
    if (selShip != null) {
        metodeKirim = (String) selShip.get("kode");
        ongkir      = (Double) selShip.get("biaya");
        kirimNama   = (String) selShip.get("nama");
    } else {
        metodeKirim = "reguler";
    }

    // ---- Hitung diskon (auto + voucher, DIGABUNG) ----
    double autoDiskon = 0;   String autoName = "";
    double voucherDiskon = 0;
    String voucherMsg = "";
    boolean voucherValid = false;
    String voucherTersimpan = "";

    try {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();

        // Diskon otomatis terbaik (yang memberi potongan terbesar)
        PreparedStatement psA = conn.prepareStatement(
            "SELECT nama, jenis_potongan, nilai, min_belanja, maks_potongan FROM master_diskon " +
            "WHERE tipe = 'auto' AND aktif = 1 " +
            "AND (tanggal_mulai IS NULL OR tanggal_mulai <= CURDATE()) " +
            "AND (tanggal_selesai IS NULL OR tanggal_selesai >= CURDATE()) " +
            "AND min_belanja <= ?");
        psA.setDouble(1, subtotalProduk);
        ResultSet rsA = psA.executeQuery();
        while (rsA.next()) {
            double pot = hitungPotongan(rsA.getString("jenis_potongan"), rsA.getDouble("nilai"),
                                        rsA.getDouble("maks_potongan"), subtotalProduk);
            if (pot > autoDiskon) { autoDiskon = pot; autoName = rsA.getString("nama"); }
        }
        rsA.close(); psA.close();

        // Voucher (jika diisi) — ditambahkan di atas diskon otomatis
        if (!voucherInput.isEmpty()) {
            PreparedStatement psV = conn.prepareStatement(
                "SELECT nama, jenis_potongan, nilai, min_belanja, maks_potongan FROM master_diskon " +
                "WHERE tipe = 'voucher' AND aktif = 1 AND kode = ? " +
                "AND (tanggal_mulai IS NULL OR tanggal_mulai <= CURDATE()) " +
                "AND (tanggal_selesai IS NULL OR tanggal_selesai >= CURDATE())");
            psV.setString(1, voucherInput);
            ResultSet rsV = psV.executeQuery();
            if (rsV.next()) {
                double minB = rsV.getDouble("min_belanja");
                if (subtotalProduk >= minB) {
                    voucherDiskon = hitungPotongan(rsV.getString("jenis_potongan"), rsV.getDouble("nilai"),
                                                   rsV.getDouble("maks_potongan"), subtotalProduk);
                    voucherValid = true;
                    voucherTersimpan = voucherInput;
                    voucherMsg = "Voucher diterapkan: " + rsV.getString("nama");
                } else {
                    voucherMsg = "Min. belanja Rp" + String.format("%,.0f", minB) + " untuk voucher ini";
                }
            } else {
                voucherMsg = "Kode voucher tidak valid / kadaluarsa";
            }
            rsV.close(); psV.close();
        }

        conn.close();
    } catch (Exception ignored) {}

    // Total diskon = auto + voucher, dibatasi agar tidak melebihi subtotal
    double diskon = autoDiskon + voucherDiskon;
    if (diskon > subtotalProduk) { diskon = subtotalProduk; voucherDiskon = Math.max(0, diskon - autoDiskon); }

    double grandTotal = subtotalProduk - diskon + ongkir;
    if (grandTotal < 0) grandTotal = 0;

    // ---- Proses pemesanan ----
    String errorMsg = "";
    String action = request.getParameter("action");

    if ("place_order".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();
        DbInit.ensureSchema(conn);
        conn.setAutoCommit(false);
        try {
            String statusBayar = "ewallet".equals(metodeBayar) ? "terverifikasi" : "menunggu";

            PreparedStatement psTrx = conn.prepareStatement(
                "INSERT INTO transaksi (id_user, total_pembayaran, status, metode_bayar, status_bayar, " +
                "metode_kirim, ongkir, diskon, kode_voucher, cancel_requested) " +
                "VALUES (?, ?, 'pending', ?, ?, ?, ?, ?, ?, 0)",
                Statement.RETURN_GENERATED_KEYS
            );
            psTrx.setInt(1, userId);
            psTrx.setDouble(2, grandTotal);
            psTrx.setString(3, metodeBayar);
            psTrx.setString(4, statusBayar);
            psTrx.setString(5, metodeKirim);
            psTrx.setDouble(6, ongkir);
            psTrx.setDouble(7, diskon);
            if (voucherValid) psTrx.setString(8, voucherTersimpan); else psTrx.setNull(8, Types.VARCHAR);
            psTrx.executeUpdate();
            ResultSet rsKeys = psTrx.getGeneratedKeys();
            int trxId = 0;
            if (rsKeys.next()) trxId = rsKeys.getInt(1);
            rsKeys.close(); psTrx.close();

            for (Map<String, Object> item : cartItems) {
                int    pid = (Integer) item.get("id");
                int    qty = (Integer) item.get("qty");
                double hj  = (Double)  item.get("harga_jual");
                double hb  = (Double)  item.get("harga_beli");
                double sub = (Double)  item.get("subtotal");

                PreparedStatement psDetail = conn.prepareStatement(
                    "INSERT INTO detail_transaksi (id_transaksi, id_product, qty, harga_beli, harga_jual, subtotal) VALUES (?,?,?,?,?,?)"
                );
                psDetail.setInt(1, trxId); psDetail.setInt(2, pid);
                psDetail.setInt(3, qty);   psDetail.setDouble(4, hb);
                psDetail.setDouble(5, hj); psDetail.setDouble(6, sub);
                psDetail.executeUpdate(); psDetail.close();

                PreparedStatement psStock = conn.prepareStatement(
                    "UPDATE master_product SET stok = stok - ? WHERE id = ? AND stok >= ?"
                );
                psStock.setInt(1, qty); psStock.setInt(2, pid); psStock.setInt(3, qty);
                psStock.executeUpdate(); psStock.close();
            }

            conn.commit(); conn.close();

            cart.clear();
            session.setAttribute("last_trx_id",     trxId);
            session.setAttribute("last_trx_total",   grandTotal);
            session.setAttribute("last_metode_bayar", metodeBayar);
            response.sendRedirect("order_success.jsp");
            return;

        } catch (Exception e) {
            conn.rollback(); conn.close();
            errorMsg = "Order failed: " + e.getMessage();
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VEND.IO - Checkout</title>
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

                <!-- Checkout Steps -->
                <div class="hidden md:flex items-center gap-0">
                    <div class="flex items-center gap-2 bg-[#4ADE80] border-[3px] border-black px-4 py-2">
                        <span class="w-6 h-6 bg-black text-white text-xs font-[900] flex items-center justify-center rounded-full">1</span>
                        <span class="font-[900] text-xs uppercase tracking-wider">Cart</span>
                    </div>
                    <div class="w-8 h-[3px] bg-black"></div>
                    <div class="flex items-center gap-2 bg-black border-[3px] border-black px-4 py-2">
                        <span class="w-6 h-6 bg-[#FACC15] text-black text-xs font-[900] flex items-center justify-center rounded-full">2</span>
                        <span class="font-[900] text-xs uppercase tracking-wider text-white">Checkout</span>
                    </div>
                    <div class="w-8 h-[3px] bg-black"></div>
                    <div class="flex items-center gap-2 bg-white border-[3px] border-black px-4 py-2 opacity-40">
                        <span class="w-6 h-6 bg-black text-white text-xs font-[900] flex items-center justify-center rounded-full">3</span>
                        <span class="font-[900] text-xs uppercase tracking-wider">Done</span>
                    </div>
                </div>

                <a href="cart.jsp" class="bg-white border-[3px] border-black px-4 py-2 font-[900] text-black tracking-widest uppercase brutal-btn hover:bg-gray-100 transition-colors text-sm">← CART</a>
            </div>
        </div>
    </header>

    <main class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h2 class="text-4xl font-[900] text-black uppercase mb-8 inline-block bg-white border-[4px] border-black px-4 py-2 brutal-btn">CHECKOUT</h2>

        <% if (!errorMsg.isEmpty()) { %>
        <div class="bg-red-200 border-[4px] border-black p-4 mb-6 brutal-shadow">
            <p class="font-[900] text-black uppercase m-0"><%= errorMsg %></p>
        </div>
        <% } %>

        <form action="checkout.jsp" method="POST">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">

            <!-- LEFT -->
            <div class="lg:col-span-2 space-y-6">

                <!-- Delivery Information -->
                <div class="bg-black p-3 brutal-shadow">
                    <div class="bg-white border-[4px] border-black">
                        <div class="px-6 py-4 border-b-[3px] border-black flex items-center gap-3">
                            <div class="bg-[#FACC15] border-[2px] border-black w-8 h-8 flex items-center justify-center font-[900] text-sm">1</div>
                            <h3 class="font-[900] text-lg uppercase m-0 tracking-wide">DELIVERY INFORMATION</h3>
                        </div>
                        <div class="p-6 grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <label class="block font-[900] text-xs uppercase tracking-widest text-gray-400 mb-2">RECIPIENT NAME</label>
                                <input type="text" name="recipient_name" value="<%= userName %>" required
                                       class="w-full border-[3px] border-black p-3 font-[900] text-black uppercase focus:outline-none focus:border-[#FACC15] transition-colors">
                            </div>
                            <div>
                                <label class="block font-[900] text-xs uppercase tracking-widest text-gray-400 mb-2">PHONE NUMBER</label>
                                <input type="text" name="recipient_phone"
                                       value="<%= userPhone.equals("-") ? "" : userPhone %>"
                                       placeholder="e.g. 08123456789"
                                       class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none focus:border-[#FACC15] transition-colors">
                            </div>
                            <div class="sm:col-span-2">
                                <label class="block font-[900] text-xs uppercase tracking-widest text-gray-400 mb-2">DELIVERY ADDRESS</label>
                                <textarea name="recipient_address" rows="2" placeholder="Enter your full delivery address"
                                          class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none focus:border-[#FACC15] transition-colors resize-none"><%= userAddress.equals("-") ? "" : userAddress %></textarea>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Order Items -->
                <div class="bg-black p-3 brutal-shadow">
                    <div class="bg-white border-[4px] border-black">
                        <div class="px-6 py-4 border-b-[3px] border-black flex items-center gap-3">
                            <div class="bg-[#FACC15] border-[2px] border-black w-8 h-8 flex items-center justify-center font-[900] text-sm">2</div>
                            <h3 class="font-[900] text-lg uppercase m-0 tracking-wide">ORDER ITEMS (<%= cartItems.size() %>)</h3>
                        </div>
                        <div class="divide-y-[2px] divide-gray-200">
                            <% for (Map<String, Object> item : cartItems) { %>
                            <div class="flex items-center gap-4 p-4">
                                <div class="w-16 h-16 border-[3px] border-black overflow-hidden flex-shrink-0">
                                    <img src="<%= item.get("image") %>" alt="<%= item.get("nama") %>" class="w-full h-full object-cover">
                                </div>
                                <div class="flex-1 min-w-0">
                                    <p class="font-[900] text-black uppercase text-sm m-0 truncate"><%= item.get("nama") %></p>
                                    <p class="font-bold text-gray-500 text-xs m-0 mt-1">Qty: <%= item.get("qty") %> &times; Rp<%= String.format("%,.0f", (Double)item.get("harga_jual")) %></p>
                                </div>
                                <p class="font-[900] text-black whitespace-nowrap ml-4">Rp<%= String.format("%,.0f", (Double)item.get("subtotal")) %></p>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <!-- Shipping Method -->
                <div class="bg-black p-3 brutal-shadow">
                    <div class="bg-white border-[4px] border-black">
                        <div class="px-6 py-4 border-b-[3px] border-black flex items-center gap-3">
                            <div class="bg-[#FACC15] border-[2px] border-black w-8 h-8 flex items-center justify-center font-[900] text-sm">3</div>
                            <h3 class="font-[900] text-lg uppercase m-0 tracking-wide">SHIPPING METHOD</h3>
                        </div>
                        <div class="p-6 space-y-3">
                            <% if (shipOpts.isEmpty()) { %>
                            <p class="font-bold text-gray-500 text-sm m-0">Belum ada metode pengiriman.</p>
                            <% } for (Map<String, Object> m : shipOpts) {
                                String kode = (String) m.get("kode");
                                boolean checked = kode.equals(metodeKirim);
                            %>
                            <label class="ship-option flex items-center justify-between gap-3 border-[3px] border-black p-3 cursor-pointer transition-colors" style="background:<%= checked ? "#FACC15" : "white" %>">
                                <div class="flex items-center gap-3">
                                    <input type="radio" name="metode_kirim" value="<%= kode %>" <%= checked ? "checked" : "" %>
                                           data-biaya="<%= (Double) m.get("biaya") %>" class="w-4 h-4 accent-black" onchange="onShipChange(this)">
                                    <div>
                                        <p class="font-[900] text-sm uppercase m-0"><%= m.get("nama") %></p>
                                        <p class="text-xs text-gray-600 m-0"><%= m.get("estimasi") %></p>
                                    </div>
                                </div>
                                <span class="font-[900] text-sm whitespace-nowrap">Rp<%= String.format("%,.0f", (Double) m.get("biaya")) %></span>
                            </label>
                            <% } %>
                        </div>
                    </div>
                </div>

                <!-- Payment Method -->
                <div class="bg-black p-3 brutal-shadow">
                    <div class="bg-white border-[4px] border-black">
                        <div class="px-6 py-4 border-b-[3px] border-black flex items-center gap-3">
                            <div class="bg-[#FACC15] border-[2px] border-black w-8 h-8 flex items-center justify-center font-[900] text-sm">4</div>
                            <h3 class="font-[900] text-lg uppercase m-0 tracking-wide">PAYMENT METHOD</h3>
                        </div>
                        <div class="p-6 grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <label class="payment-option flex items-center gap-3 border-[3px] border-black p-3 cursor-pointer transition-colors" style="background:<%= "transfer".equals(metodeBayar) ? "#FACC15" : "white" %>">
                                <input type="radio" name="metode_bayar" value="transfer" <%= "transfer".equals(metodeBayar) ? "checked" : "" %> class="w-4 h-4 accent-black" onchange="updatePayment(this)">
                                <div>
                                    <p class="font-[900] text-sm uppercase m-0">Transfer Bank</p>
                                    <p class="text-xs text-gray-600 m-0">Upload bukti transfer setelah pesan</p>
                                </div>
                            </label>
                            <label class="payment-option flex items-center gap-3 border-[3px] border-black p-3 cursor-pointer transition-colors" style="background:<%= "ewallet".equals(metodeBayar) ? "#FACC15" : "white" %>">
                                <input type="radio" name="metode_bayar" value="ewallet" <%= "ewallet".equals(metodeBayar) ? "checked" : "" %> class="w-4 h-4 accent-black" onchange="updatePayment(this)">
                                <div>
                                    <p class="font-[900] text-sm uppercase m-0">E-Wallet</p>
                                    <p class="text-xs text-gray-600 m-0">GoPay / OVO / Dana — auto verified</p>
                                </div>
                            </label>
                        </div>

                        <!-- Bank Transfer Info -->
                        <div id="bankInfoPanel" class="mx-6 mb-6 border-[3px] border-black overflow-hidden" style="display:<%= "transfer".equals(metodeBayar) ? "block" : "none" %>">
                            <div class="bg-black px-4 py-2 flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#FACC15" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="1"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                                <span class="font-[900] text-xs uppercase tracking-widest text-[#FACC15]">Rekening Tujuan Transfer</span>
                            </div>
                            <div class="bg-yellow-50 p-4 space-y-3">
                                <div class="flex items-center gap-3">
                                    <div class="bg-[#003D7C] border-[2px] border-black px-3 py-1 flex-shrink-0">
                                        <span class="font-[900] text-white text-xs tracking-widest">MANDIRI</span>
                                    </div>
                                    <div>
                                        <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0">Bank</p>
                                        <p class="font-[900] text-sm text-black m-0">Bank Mandiri</p>
                                    </div>
                                </div>
                                <div class="border-t-[2px] border-black/10 pt-3">
                                    <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">Nomor Rekening</p>
                                    <div class="flex items-stretch gap-0">
                                        <div class="flex-1 bg-white border-[3px] border-r-0 border-black px-3 py-2">
                                            <span id="noRek" class="font-[900] text-lg text-black tracking-widest select-all">1420 0123 4567 8</span>
                                        </div>
                                        <button type="button" onclick="copyNoRek()" id="copyBtn"
                                                class="bg-black text-white border-[3px] border-black px-3 py-2 font-[900] text-xs uppercase hover:bg-gray-800 transition-colors whitespace-nowrap flex items-center gap-1">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="1"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                                            SALIN
                                        </button>
                                    </div>
                                    <p id="copyFeedback" class="text-xs font-[900] text-green-600 mt-1 m-0 hidden">✓ Nomor rekening disalin!</p>
                                </div>
                                <div class="border-t-[2px] border-black/10 pt-3">
                                    <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">Atas Nama</p>
                                    <p class="font-[900] text-sm text-black m-0">VEND.IO OFFICIAL STORE</p>
                                </div>
                                <div class="bg-black/5 border-[2px] border-black/20 p-2 flex items-start gap-2">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" class="flex-shrink-0 mt-0.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                                    <p class="text-xs font-bold text-gray-600 m-0">Transfer sesuai nominal total pesanan. Upload bukti transfer setelah order dikonfirmasi.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- RIGHT: Summary -->
            <div class="lg:col-span-1">
                <div class="bg-black p-3 brutal-shadow sticky top-28">
                    <div class="bg-white border-[4px] border-black">
                        <div class="px-6 py-4 border-b-[3px] border-black">
                            <h3 class="font-[900] text-lg uppercase m-0 tracking-wide">ORDER TOTAL</h3>
                        </div>

                        <!-- Voucher -->
                        <div class="px-6 pt-5">
                            <label class="block font-[900] text-xs uppercase tracking-widest text-gray-400 mb-2">VOUCHER / PROMO CODE</label>
                            <div class="flex items-stretch">
                                <input type="text" name="kode_voucher" value="<%= voucherTersimpan.isEmpty() ? voucherInput : voucherTersimpan %>" placeholder="e.g. HEMAT5K"
                                       class="flex-1 min-w-0 border-[3px] border-r-0 border-black p-2 font-[900] text-black uppercase focus:outline-none focus:border-[#FACC15] transition-colors">
                                <button type="submit" name="action" value="apply"
                                        class="bg-black text-white border-[3px] border-black px-4 py-2 font-[900] text-xs uppercase hover:bg-gray-800 transition-colors whitespace-nowrap flex-shrink-0">APPLY</button>
                            </div>
                            <% if (!voucherMsg.isEmpty()) { %>
                            <p class="text-xs font-bold mt-2 m-0 <%= voucherValid ? "text-green-600" : "text-red-500" %>"><%= voucherMsg %></p>
                            <% } %>
                        </div>

                        <div class="p-6 space-y-3">
                            <div class="flex justify-between text-sm">
                                <span class="font-bold text-gray-500 uppercase">Subtotal</span>
                                <span class="font-bold">Rp<%= String.format("%,.0f", subtotalProduk) %></span>
                            </div>
                            <% if (autoDiskon > 0) { %>
                            <div class="flex justify-between text-sm">
                                <span class="font-bold text-gray-500 uppercase truncate mr-2">Diskon<%= autoName.isEmpty() ? "" : (" · " + autoName) %></span>
                                <span class="font-[900] text-green-600 whitespace-nowrap">− Rp<%= String.format("%,.0f", autoDiskon) %></span>
                            </div>
                            <% } if (voucherDiskon > 0) { %>
                            <div class="flex justify-between text-sm">
                                <span class="font-bold text-gray-500 uppercase truncate mr-2">Voucher<%= voucherTersimpan.isEmpty() ? "" : (" · " + voucherTersimpan) %></span>
                                <span class="font-[900] text-green-600 whitespace-nowrap">− Rp<%= String.format("%,.0f", voucherDiskon) %></span>
                            </div>
                            <% } %>
                            <div class="flex justify-between text-sm">
                                <span class="font-bold text-gray-500 uppercase">Ongkir<%= kirimNama.isEmpty() ? "" : (" · " + kirimNama) %></span>
                                <span class="font-bold whitespace-nowrap" id="ongkirDisplay">Rp<%= String.format("%,.0f", ongkir) %></span>
                            </div>

                            <div class="border-t-[3px] border-black pt-3 flex justify-between items-center">
                                <span class="font-[900] text-lg uppercase">TOTAL</span>
                                <span class="font-[900] text-2xl" id="grandTotalDisplay">Rp<%= String.format("%,.0f", grandTotal) %></span>
                            </div>
                        </div>

                        <div class="px-6 pb-6 space-y-3">
                            <button type="submit" name="action" value="place_order"
                                    class="w-full bg-[#4ADE80] border-[4px] border-black p-4 font-[900] text-black text-lg uppercase tracking-widest brutal-btn hover:bg-green-400 transition-colors flex items-center justify-center gap-2">
                                CONFIRM ORDER & PAY
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
                            </button>
                            <a href="cart.jsp" class="block text-center border-[3px] border-black p-3 font-[900] uppercase text-sm brutal-btn hover:bg-gray-100 transition-colors">
                                ← BACK TO CART
                            </a>
                        </div>
                    </div>
                </div>
            </div>

        </div>
        </form>

        <div class="text-center mt-12 pb-10">
            <p class="font-bold text-gray-400 text-sm m-0">Developed by Dandy & Verly</p>
        </div>
    </main>

    <script>
        var SUBTOTAL = <%= subtotalProduk %>;
        var DISKON = <%= diskon %>;

        function rp(n) { return 'Rp' + Math.round(n).toLocaleString('id-ID'); }

        function selectedOngkir() {
            var r = document.querySelector('input[name="metode_kirim"]:checked');
            return r ? parseFloat(r.getAttribute('data-biaya')) : 0;
        }
        function recalc() {
            var ongkir = selectedOngkir();
            document.getElementById('ongkirDisplay').textContent = rp(ongkir);
            var total = SUBTOTAL - DISKON + ongkir;
            if (total < 0) total = 0;
            document.getElementById('grandTotalDisplay').textContent = rp(total);
        }
        function onShipChange(radio) {
            document.querySelectorAll('.ship-option').forEach(function(l){ l.style.background = 'white'; });
            radio.closest('.ship-option').style.background = '#FACC15';
            recalc();
        }
        function updatePayment(radio) {
            document.querySelectorAll('.payment-option').forEach(function(l){ l.style.background = 'white'; });
            radio.closest('.payment-option').style.background = '#FACC15';
            var panel = document.getElementById('bankInfoPanel');
            if (panel) panel.style.display = (radio.value === 'transfer') ? 'block' : 'none';
        }
        function copyNoRek() {
            var noRek = document.getElementById('noRek').textContent.replace(/\s/g, '');
            navigator.clipboard.writeText(noRek).then(function() {
                var btn = document.getElementById('copyBtn');
                var fb  = document.getElementById('copyFeedback');
                btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg> DISALIN!';
                btn.classList.add('bg-green-700');
                fb.classList.remove('hidden');
                setTimeout(function(){
                    btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="1"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg> SALIN';
                    btn.classList.remove('bg-green-700');
                    fb.classList.add('hidden');
                }, 2500);
            });
        }
    </script>
</body>
</html>
