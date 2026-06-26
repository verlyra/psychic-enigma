<%@page import="jdbc.koneksi"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    boolean isLoggedIn = session.getAttribute("user_id") != null;
    String userName = isLoggedIn ? (String) session.getAttribute("nama_lengkap") : "Guest";

    Map<String, Integer> cartSession = (Map<String, Integer>) session.getAttribute("cart");
    int cartCount = 0;
    if (cartSession != null) {
        for (int qty : cartSession.values()) cartCount += qty;
    }

    String pidStr = request.getParameter("id");
    if (pidStr == null || pidStr.isEmpty()) {
        response.sendRedirect("index.jsp");
        return;
    }

    int productId = 0;
    try { productId = Integer.parseInt(pidStr); } catch (NumberFormatException e) {
        response.sendRedirect("index.jsp");
        return;
    }

    String prodName = null, prodMerk = "", prodImg = "", prodDeskripsi = "";
    String prodKategori = "", prodUkuran = "";
    double prodPrice = 0;
    int prodStok = 0;

    try {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();
        PreparedStatement ps = conn.prepareStatement(
            "SELECT p.*, k.nama_kategori, u.nama_ukuran " +
            "FROM master_product p " +
            "LEFT JOIN master_kategori k ON p.id_kategori = k.id " +
            "LEFT JOIN master_ukuran u ON p.id_ukuran = u.id " +
            "WHERE p.id = ?"
        );
        ps.setInt(1, productId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            prodName     = rs.getString("nama_produk");
            prodMerk     = rs.getString("merk")         != null ? rs.getString("merk")         : "";
            prodPrice    = rs.getDouble("harga_jual");
            prodStok     = rs.getInt("stok");
            prodImg      = rs.getString("image_url");
            prodDeskripsi= rs.getString("deskripsi")    != null ? rs.getString("deskripsi")    : "";
            prodKategori = rs.getString("nama_kategori") != null ? rs.getString("nama_kategori") : "";
            prodUkuran   = rs.getString("nama_ukuran")   != null ? rs.getString("nama_ukuran")   : "";
            if (prodImg == null || prodImg.trim().isEmpty())
                prodImg = "https://via.placeholder.com/600/ffffff/000000?text=NO+IMAGE";
        }
        rs.close(); ps.close(); conn.close();
    } catch (Exception ignored) {}

    if (prodName == null) {
        response.sendRedirect("index.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VEND.IO - <%= prodName %></title>
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
                    <% if (isLoggedIn) { %>
                    <div class="text-right hidden md:block">
                        <p class="text-xs font-[900] text-black tracking-widest uppercase m-0">HELLO,</p>
                        <p class="text-lg font-[900] text-black uppercase m-0"><%= userName %></p>
                    </div>
                    <a href="cart.jsp" class="relative bg-white border-[3px] border-black p-2 brutal-btn hover:bg-gray-100 transition-colors" title="Cart">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                        </svg>
                        <% if (cartCount > 0) { %>
                        <span class="absolute -top-2 -right-2 bg-red-500 text-white text-xs font-[900] min-w-[20px] h-5 flex items-center justify-center border-[2px] border-black px-1 leading-none">
                            <%= cartCount %>
                        </span>
                        <% } %>
                    </a>
                    <a href="logout.jsp" class="bg-white border-[3px] border-black p-2 brutal-btn hover:bg-red-500 hover:text-white transition-colors" title="Logout">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                    </a>
                    <% } else { %>
                    <a href="login.jsp" class="bg-white border-[3px] border-black px-4 py-2 font-[900] text-black tracking-widest uppercase brutal-btn hover:bg-gray-100 transition-colors">LOGIN</a>
                    <a href="register.jsp" class="bg-[#4ADE80] border-[3px] border-black px-4 py-2 font-[900] text-black tracking-widest uppercase brutal-btn hover:bg-green-500 transition-colors">REGISTER</a>
                    <% } %>
                </div>
            </div>
        </div>
    </header>

    <main class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10">

        <!-- Breadcrumb -->
        <div class="flex items-center gap-2 mb-8">
            <a href="index.jsp" class="font-[900] text-sm uppercase tracking-wider text-black border-b-[3px] border-black hover:border-[#FACC15] transition-colors">← BACK TO STORE</a>
        </div>

        <!-- Product Detail Card -->
        <div class="bg-black p-3 brutal-shadow">
            <div class="bg-white border-[4px] border-black">
                <div class="grid grid-cols-1 md:grid-cols-2">

                    <!-- Image -->
                    <div class="border-b-[4px] md:border-b-0 md:border-r-[4px] border-black">
                        <div class="aspect-square overflow-hidden">
                            <img src="<%= prodImg %>" alt="<%= prodName %>" class="w-full h-full object-cover">
                        </div>
                    </div>

                    <!-- Info -->
                    <div class="p-8 flex flex-col gap-0">

                        <!-- Badges: category + brand -->
                        <div class="flex flex-wrap gap-2 mb-4">
                            <% if (!prodKategori.isEmpty()) { %>
                            <span class="bg-black text-white border-[2px] border-black px-3 py-1 font-[900] text-xs uppercase tracking-widest"><%= prodKategori %></span>
                            <% } %>
                            <% if (!prodMerk.isEmpty()) { %>
                            <span class="bg-[#FACC15] border-[2px] border-black px-3 py-1 font-[900] text-xs uppercase tracking-widest"><%= prodMerk %></span>
                            <% } %>
                        </div>

                        <!-- Name -->
                        <h2 class="font-[900] text-4xl uppercase text-black leading-none mb-5 m-0"><%= prodName %></h2>

                        <!-- Price -->
                        <div class="border-t-[3px] border-black pt-5 mb-5">
                            <p class="font-[900] text-5xl text-black m-0">Rp<%= String.format("%,.0f", prodPrice) %></p>
                        </div>

                        <!-- Details grid: unit + stock -->
                        <div class="grid grid-cols-2 gap-3 mb-5">
                            <% if (!prodUkuran.isEmpty()) { %>
                            <div class="border-[3px] border-black p-3">
                                <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">SIZE / UNIT</p>
                                <p class="font-[900] text-sm uppercase text-black m-0"><%= prodUkuran %></p>
                            </div>
                            <% } %>
                            <div class="border-[3px] border-black p-3">
                                <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-1">AVAILABILITY</p>
                                <% if (prodStok > 0) { %>
                                <div class="flex items-center gap-2">
                                    <span class="w-2.5 h-2.5 bg-[#4ADE80] border-[2px] border-black inline-block flex-shrink-0"></span>
                                    <span class="font-[900] text-sm uppercase text-black"><%= prodStok %> IN STOCK</span>
                                </div>
                                <% } else { %>
                                <div class="flex items-center gap-2">
                                    <span class="w-2.5 h-2.5 bg-red-500 border-[2px] border-black inline-block flex-shrink-0"></span>
                                    <span class="font-[900] text-sm uppercase text-red-500">OUT OF STOCK</span>
                                </div>
                                <% } %>
                            </div>
                        </div>

                        <!-- Description -->
                        <% if (!prodDeskripsi.isEmpty()) { %>
                        <div class="border-t-[3px] border-black pt-5 mb-5">
                            <p class="font-[900] text-[10px] uppercase tracking-widest text-gray-400 m-0 mb-2">DESCRIPTION</p>
                            <p class="font-bold text-sm text-gray-700 leading-relaxed m-0"><%= prodDeskripsi %></p>
                        </div>
                        <% } %>

                        <!-- Add to Cart -->
                        <div class="mt-auto flex flex-col gap-3 pt-5 border-t-[3px] border-black">
                            <% if (prodStok > 0) { %>
                                <% if (isLoggedIn) { %>
                                <a href="cart.jsp?action=add&id=<%= productId %>"
                                   class="bg-[#FACC15] border-[4px] border-black px-6 py-4 font-[900] text-black text-lg uppercase tracking-widest brutal-btn hover:bg-yellow-400 transition-colors text-center flex items-center justify-center gap-3">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                                    </svg>
                                    ADD TO CART
                                </a>
                                <% } else { %>
                                <a href="login.jsp"
                                   class="bg-[#FACC15] border-[4px] border-black px-6 py-4 font-[900] text-black text-lg uppercase tracking-widest brutal-btn hover:bg-yellow-400 transition-colors text-center">
                                    LOGIN TO ADD TO CART
                                </a>
                                <% } %>
                            <% } else { %>
                            <div class="bg-gray-200 border-[4px] border-gray-300 px-6 py-4 font-[900] text-gray-400 text-lg uppercase tracking-widest text-center">
                                OUT OF STOCK
                            </div>
                            <% } %>
                            <a href="index.jsp"
                               class="bg-white border-[4px] border-black px-6 py-3 font-[900] text-black uppercase tracking-widest brutal-btn hover:bg-gray-100 transition-colors text-center text-sm">
                                CONTINUE SHOPPING
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="text-center mt-12 pb-10">
            <p class="font-bold text-gray-400 text-sm m-0">Developed by Dandy & Verly</p>
        </div>
    </main>

</body>
</html>
