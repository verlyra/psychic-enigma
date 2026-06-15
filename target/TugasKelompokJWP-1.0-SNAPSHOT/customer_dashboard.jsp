<%@page import="jdbc.koneksi"%>
<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Cek session login
    if(session.getAttribute("user_id") == null) {
        response.sendRedirect("index.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VEND.IO - Store</title>
    <!-- Tailwind CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background-color: #e5e7eb; }
        .brutal-shadow { box-shadow: 8px 8px 0px 0px rgba(0,0,0,1); }
        .brutal-btn { box-shadow: 4px 4px 0px 0px rgba(0,0,0,1); }
        .brutal-btn:active { box-shadow: 0px 0px 0px 0px rgba(0,0,0,1); transform: translate(4px, 4px); }
    </style>
</head>
<body class="min-h-screen">

    <!-- Header / Navbar -->
    <header class="bg-[#FACC15] border-b-[4px] border-black sticky top-0 z-50">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-20">
                <!-- Logo -->
                <div class="flex items-center gap-3">
                    <div class="bg-white border-[3px] border-black p-2 brutal-btn">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                        </svg>
                    </div>
                    <h1 class="text-3xl font-[900] italic tracking-tighter text-black">VEND.IO</h1>
                </div>

                <!-- Search -->
                <div class="flex-1 max-w-xl mx-8 hidden md:block">
                    <div class="relative">
                        <input type="text" placeholder="Search for items..." class="w-full bg-white border-[3px] border-black py-3 pl-4 pr-10 font-[900] placeholder:text-gray-400 focus:outline-none brutal-btn">
                        <svg class="absolute right-4 top-3 text-black" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                    </div>
                </div>

                <!-- User & Cart -->
                <div class="flex items-center gap-6">
                    <div class="text-right hidden md:block">
                        <p class="text-xs font-[900] text-black tracking-widest uppercase">HELLO,</p>
                        <p class="text-lg font-[900] text-black uppercase"><%= session.getAttribute("nama_lengkap") %></p>
                    </div>
                    <a href="logout.jsp" class="bg-white border-[3px] border-black p-2 brutal-btn hover:bg-red-500 hover:text-white transition-colors" title="Logout">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                    </a>
                </div>
            </div>
        </div>
    </header>

    <!-- Main Content: Catalog -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        
        <div class="mb-12 bg-[#4ADE80] border-[4px] border-black p-8 md:p-12 brutal-shadow flex items-center justify-between relative overflow-hidden">
            <div class="relative z-10">
                <h2 class="text-4xl md:text-5xl font-[900] text-black mb-4 uppercase tracking-tighter drop-shadow-[2px_2px_0px_rgba(255,255,255,1)]">FRESH & FAST</h2>
                <p class="text-black font-bold text-lg md:text-xl border-l-[4px] border-black pl-4">Order now, we deliver in minutes!</p>
            </div>
            <div class="hidden md:block relative z-10">
                 <svg class="text-black drop-shadow-[4px_4px_0px_rgba(255,255,255,1)]" xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l2.5-4H18l2 4M3 12h18v8H3z"></path></svg>
            </div>
            <div class="absolute -right-10 -bottom-10 opacity-20 transform rotate-12">
                 <svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="4"><circle cx="12" cy="12" r="10"></circle></svg>
            </div>
        </div>

        <h3 class="text-3xl font-[900] text-black uppercase mb-8 inline-block bg-white border-[4px] border-black px-4 py-2 brutal-btn">ALL ITEMS</h3>

        <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-6 md:gap-8">
            <%
                try {
                    koneksi k = new koneksi();
                    Connection conn = k.bukaKoneksi();
                    if (conn != null) {
                        Statement stmt = conn.createStatement();
                        ResultSet rs = stmt.executeQuery("SELECT * FROM master_product ORDER BY id DESC");
                        
                        boolean hasData = false;
                        while(rs.next()) {
                            hasData = true;
                            String img = rs.getString("image_url");
                            if(img == null || img.trim().isEmpty()) {
                                img = "https://via.placeholder.com/200/ffffff/000000?text=NO+IMAGE";
                            }
            %>
            
            <!-- Product Card -->
            <div class="bg-white border-[4px] border-black p-4 brutal-btn flex flex-col h-full hover:-translate-y-2 transition-transform duration-200 cursor-pointer">
                <div class="aspect-square border-[3px] border-black mb-4 overflow-hidden bg-gray-100">
                    <img src="<%= img %>" alt="<%= rs.getString("nama_produk") %>" class="w-full h-full object-cover">
                </div>
                <h4 class="font-[900] text-black text-lg uppercase leading-tight mb-2 flex-1"><%= rs.getString("nama_produk") %></h4>
                <div class="mt-auto">
                    <p class="font-[900] text-2xl text-black mb-3">Rp<%= String.format("%,.0f", rs.getDouble("harga")) %></p>
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-[900] text-black border-[2px] border-black px-2 py-1 uppercase bg-[#FACC15]">STOCK: <%= rs.getInt("stok") %></span>
                        <button class="bg-[#3498DB] text-white border-[3px] border-black w-10 h-10 flex items-center justify-center brutal-btn hover:bg-blue-600 transition-colors">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                        </button>
                    </div>
                </div>
            </div>

            <%
                        }
                        if(!hasData) {
            %>
                        <div class="col-span-full py-20 text-center">
                            <div class="bg-white border-[4px] border-black inline-block p-10 brutal-shadow">
                                <p class="font-[900] text-2xl text-black uppercase tracking-widest">No Items Available.</p>
                            </div>
                        </div>
            <%
                        }
                        rs.close();
                        stmt.close();
                        conn.close();
                    }
                } catch(Exception e) {
            %>
                    <div class="col-span-full py-12 text-center text-red-500 font-bold">
                        <p>Error: <%= e.getMessage() %></p>
                    </div>
            <%  } %>

        </div>
        
        <div class="text-center mt-20 pb-10">
            <p class="font-bold text-gray-400 text-sm">Developed by Dandy & Verly</p>
        </div>
    </main>

</body>
</html>
