<%@page import="jdbc.koneksi"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("user_id") == null || session.getAttribute("last_trx_id") == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    int    trxId    = (Integer) session.getAttribute("last_trx_id");
    String userName = (String)  session.getAttribute("nama_lengkap");

    List<Map<String, Object>> trxItems = new ArrayList<>();
    String trxDate    = "-";
    double trxTotal   = 0;
    double ongkir     = 0;
    double diskon     = 0;
    String metodeBayar = "transfer";
    String statusBayar = "menunggu";
    String metodeKirim = "-";
    String buktiTransfer = null;
    double itemsSubtotal = 0;

    try {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();

        PreparedStatement psTrx = conn.prepareStatement(
            "SELECT t.tanggal, t.total_pembayaran, t.ongkir, t.diskon, t.metode_bayar, " +
            "t.status_bayar, t.bukti_transfer, p.nama AS kirim_nama " +
            "FROM transaksi t LEFT JOIN master_pengiriman p ON t.metode_kirim = p.kode " +
            "WHERE t.id = ?");
        psTrx.setInt(1, trxId);
        ResultSet rsTrx = psTrx.executeQuery();
        if (rsTrx.next()) {
            trxDate      = rsTrx.getString("tanggal");
            trxTotal     = rsTrx.getDouble("total_pembayaran");
            ongkir       = rsTrx.getDouble("ongkir");
            diskon       = rsTrx.getDouble("diskon");
            metodeBayar  = rsTrx.getString("metode_bayar");
            statusBayar  = rsTrx.getString("status_bayar");
            buktiTransfer = rsTrx.getString("bukti_transfer");
            metodeKirim  = rsTrx.getString("kirim_nama") != null ? rsTrx.getString("kirim_nama") : "-";
        }
        rsTrx.close(); psTrx.close();

        PreparedStatement psDetail = conn.prepareStatement(
            "SELECT d.qty, d.harga_jual, d.subtotal, p.nama_produk, p.image_url " +
            "FROM detail_transaksi d JOIN master_product p ON d.id_product = p.id " +
            "WHERE d.id_transaksi = ?"
        );
        psDetail.setInt(1, trxId);
        ResultSet rsDetail = psDetail.executeQuery();
        while (rsDetail.next()) {
            Map<String, Object> item = new HashMap<>();
            String img = rsDetail.getString("image_url");
            if (img == null || img.trim().isEmpty()) img = "https://via.placeholder.com/64/ffffff/000000?text=IMG";
            item.put("nama",     rsDetail.getString("nama_produk"));
            item.put("image",    img);
            item.put("qty",      rsDetail.getInt("qty"));
            item.put("harga",    rsDetail.getDouble("harga_jual"));
            item.put("subtotal", rsDetail.getDouble("subtotal"));
            itemsSubtotal += rsDetail.getDouble("subtotal");
            trxItems.add(item);
        }
        rsDetail.close(); psDetail.close();
        conn.close();
    } catch (Exception ignored) {}

    boolean butuhBukti = "transfer".equalsIgnoreCase(metodeBayar) && (buktiTransfer == null || buktiTransfer.isEmpty());
    boolean butuhQris   = "ewallet".equalsIgnoreCase(metodeBayar);

    String bayarBadge, bayarLabel;
    if ("terverifikasi".equalsIgnoreCase(statusBayar)) { bayarBadge = "bg-[#4ADE80] text-black"; bayarLabel = "Terverifikasi"; }
    else if ("ditolak".equalsIgnoreCase(statusBayar)) { bayarBadge = "bg-red-400 text-black";  bayarLabel = "Ditolak"; }
    else { bayarBadge = "bg-gray-300 text-black"; bayarLabel = "Menunggu Verifikasi"; }

    // Bersihkan supaya refresh kembali ke store
    session.removeAttribute("last_trx_id");
    session.removeAttribute("last_trx_total");
    session.removeAttribute("last_metode_bayar");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VEND.IO - Order Confirmed</title>
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
    <header class="bg-[#FACC15] border-b-[4px] border-black">
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
                <a href="order_history.jsp" class="bg-white border-[3px] border-black px-4 py-2 font-[900] text-black tracking-widest uppercase brutal-btn hover:bg-gray-100 transition-colors text-sm">MY ORDERS</a>
            </div>
        </div>
    </header>

    <main class="max-w-3xl mx-auto px-4 sm:px-6 py-12">

        <!-- Success Banner -->
        <div class="bg-[#4ADE80] border-[4px] border-black p-8 brutal-shadow mb-8">
            <div class="flex flex-col sm:flex-row items-center sm:items-start gap-6">
                <div class="w-16 h-16 bg-black border-[3px] border-black flex items-center justify-center flex-shrink-0">
                    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#4ADE80" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </div>
                <div>
                    <h2 class="font-[900] text-3xl uppercase text-black m-0">ORDER PLACED!</h2>
                    <p class="font-bold text-black mt-1 m-0">
                        Hi <span class="font-[900] uppercase"><%= userName %></span>, your order has been confirmed.
                    </p>
                    <p class="font-bold text-sm text-black opacity-70 mt-1 m-0">
                        Order #<%= trxId %> &bull; <%= trxDate %>
                    </p>
                </div>
            </div>
        </div>

        <!-- QRIS E-Wallet Panel -->
        <% if (butuhQris) { %>
        <div id="qrisPanel" class="bg-white border-[4px] border-black brutal-shadow mb-6 overflow-hidden">
            <!-- Header -->
            <div class="bg-black px-5 py-3 flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#FACC15" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3m0 0h3m-3 0v3"/></svg>
                    <span class="font-[900] text-xs uppercase tracking-widest text-[#FACC15]">QRIS · E-Wallet</span>
                </div>
                <span class="font-[900] text-xs text-white opacity-60">GoPay · OVO · Dana · ShopeePay</span>
            </div>

            <div class="p-6 flex flex-col md:flex-row gap-8 items-center">
                <!-- QR Code Image -->
                <div class="flex-shrink-0 flex flex-col items-center">
                    <img src="uploads/qris_dummy.png" alt="QRIS Payment Code"
                         class="w-56 h-56 object-contain block border-[3px] border-black">
                    <p class="text-[10px] font-[900] uppercase tracking-widest text-gray-400 mt-2 m-0">QRIS · Pembayaran Terverifikasi</p>
                </div>

                <!-- Right side info -->
                <div class="flex-1 space-y-4 w-full">
                    <div>
                        <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">Jumlah Pembayaran</p>
                        <p class="font-[900] text-3xl text-black m-0">Rp<%= String.format("%,.0f", trxTotal) %></p>
                    </div>
                    <div class="border-t-[2px] border-gray-200 pt-4">
                        <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">Merchant</p>
                        <p class="font-[900] text-sm text-black m-0">VEND.IO OFFICIAL STORE</p>
                    </div>
                    <div class="bg-[#4ADE80] border-[3px] border-black p-4 flex items-center gap-3">
                        <div class="w-10 h-10 bg-black flex items-center justify-center flex-shrink-0">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4ADE80" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                        </div>
                        <div>
                            <p class="font-[900] text-sm uppercase text-black m-0">Pembayaran Terverifikasi!</p>
                            <p class="font-bold text-xs text-black m-0">Pesananmu sedang diproses.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <% } %>

        <!-- Upload bukti transfer (jika transfer & belum upload) -->
        <% if (butuhBukti) { %>
        <!-- Info Rekening -->
        <div class="bg-white border-[4px] border-black brutal-shadow mb-4 overflow-hidden">
            <div class="bg-black px-5 py-3 flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#FACC15" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="1"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                <span class="font-[900] text-xs uppercase tracking-widest text-[#FACC15]">Rekening Tujuan Transfer</span>
            </div>
            <div class="p-5 space-y-3">
                <div class="flex items-center gap-3">
                    <div class="bg-[#003D7C] border-[2px] border-black px-3 py-1 flex-shrink-0">
                        <span class="font-[900] text-white text-xs tracking-widest">MANDIRI</span>
                    </div>
                    <div>
                        <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0">Bank</p>
                        <p class="font-[900] text-sm text-black m-0">Bank Mandiri</p>
                    </div>
                </div>
                <div class="border-t-[2px] border-gray-200 pt-3">
                    <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">Nomor Rekening</p>
                    <div class="flex items-stretch gap-0">
                        <div class="flex-1 bg-gray-50 border-[3px] border-r-0 border-black px-4 py-3">
                            <span id="noRekSuccess" class="font-[900] text-2xl text-black tracking-widest select-all">1420 0123 4567 8</span>
                        </div>
                        <button type="button" onclick="copyNoRekSuccess()" id="copyBtnSuccess"
                                class="bg-black text-white border-[3px] border-black px-4 py-3 font-[900] text-xs uppercase hover:bg-gray-800 transition-colors whitespace-nowrap flex items-center gap-1">
                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="1"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                            SALIN
                        </button>
                    </div>
                    <p id="copyFeedbackSuccess" class="text-xs font-[900] text-green-600 mt-1 m-0" style="display:none">&check; Nomor rekening disalin!</p>
                </div>
                <div class="border-t-[2px] border-gray-200 pt-3 grid grid-cols-2 gap-3">
                    <div>
                        <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">Atas Nama</p>
                        <p class="font-[900] text-sm text-black m-0">VEND.IO OFFICIAL STORE</p>
                    </div>
                    <div>
                        <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">Jumlah Transfer</p>
                        <p class="font-[900] text-sm text-black m-0">Rp<%= String.format("%,.0f", trxTotal) %></p>
                    </div>
                </div>
                <div class="bg-yellow-50 border-[2px] border-[#FACC15] p-3 flex items-start gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#92400E" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" class="flex-shrink-0 mt-0.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                    <p class="text-xs font-bold text-yellow-800 m-0">Transfer tepat sesuai nominal di atas agar verifikasi lebih cepat, lalu upload bukti transfer di bawah ini.</p>
                </div>
            </div>
        </div>

        <div class="bg-[#FACC15] border-[4px] border-black p-6 brutal-shadow mb-8">
            <h3 class="font-[900] text-lg uppercase m-0 mb-2">UPLOAD BUKTI TRANSFER</h3>
            <p class="font-bold text-sm text-black mb-4 m-0">Pesananmu menunggu pembayaran. Upload bukti transfer agar admin dapat memverifikasinya.</p>
            <form action="UploadBukti" method="POST" enctype="multipart/form-data" class="flex flex-col sm:flex-row gap-3">
                <input type="hidden" name="order_id" value="<%= trxId %>">
                <input type="file" name="bukti" accept="image/*" required
                       class="flex-1 border-[3px] border-black p-2 font-bold text-black bg-white focus:outline-none">
                <button type="submit" class="bg-black text-white border-[3px] border-black px-6 py-2 font-[900] uppercase text-sm tracking-widest brutal-btn hover:bg-gray-800 transition-colors whitespace-nowrap">
                    UPLOAD BUKTI
                </button>
            </form>
        </div>
        <% } %>

        <!-- Order Details Card -->
        <div class="bg-black p-3 brutal-shadow mb-6">
            <div class="bg-white border-[4px] border-black">
                <div class="px-6 py-4 border-b-[3px] border-black flex items-center justify-between flex-wrap gap-2">
                    <h3 class="font-[900] text-lg uppercase m-0">ORDER DETAILS</h3>
                    <span class="bg-[#FACC15] border-[2px] border-black px-3 py-1 font-[900] text-xs uppercase">ORDER #<%= trxId %></span>
                </div>

                <!-- Payment & shipping info -->
                <div class="px-6 py-4 border-b-[2px] border-gray-100 grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">PAYMENT</p>
                        <p class="font-[900] text-sm uppercase m-0"><%= "ewallet".equalsIgnoreCase(metodeBayar) ? "E-Wallet" : "Transfer Bank" %></p>
                        <span class="inline-block mt-1 border-[2px] border-black px-2 py-0.5 font-[900] text-[10px] uppercase <%= bayarBadge %>"><%= bayarLabel %></span>
                    </div>
                    <div>
                        <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">SHIPPING</p>
                        <p class="font-[900] text-sm uppercase m-0"><%= metodeKirim %></p>
                    </div>
                </div>

                <!-- Items -->
                <div class="divide-y-[2px] divide-gray-100">
                    <% for (Map<String, Object> item : trxItems) { %>
                    <div class="flex items-center gap-4 p-4">
                        <div class="w-14 h-14 border-[3px] border-black overflow-hidden flex-shrink-0">
                            <img src="<%= item.get("image") %>" alt="<%= item.get("nama") %>" class="w-full h-full object-cover">
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="font-[900] text-black uppercase text-sm m-0 truncate"><%= item.get("nama") %></p>
                            <p class="font-bold text-gray-500 text-xs m-0">
                                <%= item.get("qty") %> item &times; Rp<%= String.format("%,.0f", (Double)item.get("harga")) %>
                            </p>
                        </div>
                        <p class="font-[900] text-black whitespace-nowrap text-sm">Rp<%= String.format("%,.0f", (Double)item.get("subtotal")) %></p>
                    </div>
                    <% } %>
                </div>

                <!-- Totals -->
                <div class="px-6 py-4 border-t-[2px] border-gray-100 space-y-2">
                    <div class="flex justify-between text-sm">
                        <span class="font-bold text-gray-500 uppercase">Subtotal</span>
                        <span class="font-bold">Rp<%= String.format("%,.0f", itemsSubtotal) %></span>
                    </div>
                    <% if (diskon > 0) { %>
                    <div class="flex justify-between text-sm">
                        <span class="font-bold text-gray-500 uppercase">Diskon</span>
                        <span class="font-[900] text-green-600">− Rp<%= String.format("%,.0f", diskon) %></span>
                    </div>
                    <% } %>
                    <div class="flex justify-between text-sm">
                        <span class="font-bold text-gray-500 uppercase">Ongkir</span>
                        <span class="font-bold">Rp<%= String.format("%,.0f", ongkir) %></span>
                    </div>
                </div>
                <div class="px-6 py-4 border-t-[3px] border-black bg-gray-50 flex justify-between items-center">
                    <span class="font-[900] uppercase text-sm tracking-wider">ORDER TOTAL</span>
                    <span class="font-[900] text-2xl">Rp<%= String.format("%,.0f", trxTotal) %></span>
                </div>
            </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex flex-col sm:flex-row gap-3">
            <a href="order_history.jsp" class="flex-1 bg-white border-[4px] border-black px-6 py-3 font-[900] text-black uppercase tracking-widest brutal-btn hover:bg-gray-100 transition-colors flex items-center justify-center gap-2">
                VIEW MY ORDERS
            </a>
            <a href="index.jsp" class="flex-1 bg-[#FACC15] border-[4px] border-black px-6 py-3 font-[900] text-black uppercase tracking-widest brutal-btn hover:bg-yellow-400 transition-colors flex items-center justify-center gap-2">
                CONTINUE SHOPPING
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
            </a>
        </div>

        <div class="text-center mt-10 pb-6">
            <p class="font-bold text-gray-400 text-sm m-0">Developed by Dandy & Verly</p>
        </div>
    </main>

    <script>
        function copyNoRekSuccess() {
            var noRek = document.getElementById('noRekSuccess').textContent.replace(/\s/g, '');
            navigator.clipboard.writeText(noRek).then(function() {
                var btn = document.getElementById('copyBtnSuccess');
                var fb  = document.getElementById('copyFeedbackSuccess');
                btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg> DISALIN!';
                btn.classList.add('bg-green-700');
                fb.style.display = 'block';
                setTimeout(function(){
                    btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="1"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg> SALIN';
                    btn.classList.remove('bg-green-700');
                    fb.style.display = 'none';
                }, 2500);
            });
        }

        function startQrisScan(orderId) {
            // Sembunyikan tombol, tampilkan progress
            var scanBtn      = document.getElementById('scanBtn');
            var qrisProgress = document.getElementById('qrisProgress');
            var qrisBar      = document.getElementById('qrisBar');
            var qrisCountdown= document.getElementById('qrisCountdown');
            var qrisStatusTxt= document.getElementById('qrisStatusText');
            var qrisSuccess  = document.getElementById('qrisSuccess');

            scanBtn.disabled = true;
            scanBtn.classList.add('opacity-50', 'cursor-not-allowed');
            qrisProgress.classList.remove('hidden');

            var totalMs  = 5000;
            var interval = 50;
            var elapsed  = 0;
            var phases   = [
                { pct: 20,  label: 'Menghubungi server bank...' },
                { pct: 50,  label: 'Memverifikasi identitas...' },
                { pct: 75,  label: 'Memproses transaksi...' },
                { pct: 95,  label: 'Menyelesaikan pembayaran...' },
            ];
            var phaseIdx = 0;

            var timer = setInterval(function() {
                elapsed += interval;
                var pct = Math.min((elapsed / totalMs) * 100, 99);
                qrisBar.style.width = pct + '%';
                var remaining = Math.ceil((totalMs - elapsed) / 1000);
                qrisCountdown.textContent = remaining > 0 ? remaining + 's' : '...';

                if (phaseIdx < phases.length && pct >= phases[phaseIdx].pct) {
                    qrisStatusTxt.textContent = phases[phaseIdx].label;
                    phaseIdx++;
                }

                if (elapsed >= totalMs) {
                    clearInterval(timer);
                    qrisBar.style.width = '100%';
                    qrisCountdown.textContent = '✓';
                    qrisStatusTxt.textContent = 'Konfirmasi pembayaran...';

                    // AJAX ke servlet VerifQris
                    var formData = new FormData();
                    formData.append('order_id', orderId);
                    fetch('VerifQris', { method: 'POST', body: formData })
                        .then(function(r){ return r.json(); })
                        .then(function(data) {
                            if (data.ok) {
                                // Tampilkan sukses
                                qrisProgress.classList.add('hidden');
                                scanBtn.classList.add('hidden');
                                qrisSuccess.classList.remove('hidden');
                                qrisSuccess.classList.add('flex');
                                // Redirect ke order history setelah 2.5 detik
                                setTimeout(function(){ window.location.href = 'order_history.jsp'; }, 2500);
                            } else {
                                qrisStatusTxt.textContent = 'Gagal: ' + data.msg;
                                qrisBar.style.backgroundColor = '#f87171';
                                scanBtn.disabled = false;
                                scanBtn.classList.remove('opacity-50','cursor-not-allowed');
                            }
                        })
                        .catch(function() {
                            qrisStatusTxt.textContent = 'Koneksi gagal, coba lagi.';
                            qrisBar.style.backgroundColor = '#f87171';
                            scanBtn.disabled = false;
                            scanBtn.classList.remove('opacity-50','cursor-not-allowed');
                        });
                }
            }, interval);
        }
    </script>
</body>
</html>

