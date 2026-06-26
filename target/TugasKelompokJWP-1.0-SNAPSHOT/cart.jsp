<%@page import="jdbc.koneksi"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("user_id") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Map<String, Integer> cart = (Map<String, Integer>) session.getAttribute("cart");
    if (cart == null) {
        cart = new LinkedHashMap<>();
        session.setAttribute("cart", cart);
    }

    String action = request.getParameter("action");

    if ("add".equals(action)) {
        String pid = request.getParameter("id");
        if (pid != null && !pid.isEmpty()) {
            try {
                int productId = Integer.parseInt(pid);
                koneksi k = new koneksi();
                Connection connChk = k.bukaKoneksi();
                PreparedStatement psChk = connChk.prepareStatement("SELECT stok FROM master_product WHERE id = ?");
                psChk.setInt(1, productId);
                ResultSet rsChk = psChk.executeQuery();
                if (rsChk.next()) {
                    int maxStock = rsChk.getInt("stok");
                    if (maxStock > 0) {
                        String key = String.valueOf(productId);
                        int currentQty = cart.getOrDefault(key, 0);
                        if (currentQty < maxStock) {
                            cart.put(key, currentQty + 1);
                        }
                    }
                }
                rsChk.close(); psChk.close(); connChk.close();
            } catch (NumberFormatException ignored) {}
        }
        response.sendRedirect("index.jsp");
        return;
    } else if ("update".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        String pid = request.getParameter("id");
        String qtyStr = request.getParameter("qty");
        if (pid != null && qtyStr != null) {
            try {
                int qty = Integer.parseInt(qtyStr);
                if (qty <= 0) {
                    cart.remove(pid);
                } else {
                    cart.put(pid, qty);
                }
            } catch (NumberFormatException ignored) {}
        }
        response.sendRedirect("cart.jsp");
        return;
    } else if ("remove".equals(action)) {
        String pid = request.getParameter("id");
        if (pid != null) cart.remove(pid);
        response.sendRedirect("cart.jsp");
        return;
    } else if ("clear".equals(action)) {
        cart.clear();
        response.sendRedirect("cart.jsp");
        return;
    }

    // Load cart items from DB
    String userName = (String) session.getAttribute("nama_lengkap");
    List<Map<String, Object>> cartItems = new ArrayList<>();
    double cartTotal = 0;

    if (!cart.isEmpty()) {
        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
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
                        if (img == null || img.trim().isEmpty()) img = "https://via.placeholder.com/80/ffffff/000000?text=NO+IMG";
                        item.put("id", rs.getInt("id"));
                        item.put("nama", rs.getString("nama_produk"));
                        item.put("harga", rs.getDouble("harga_jual"));
                        item.put("stok", stok);
                        item.put("image", img);
                        item.put("qty", qty);
                        double subtotal = rs.getDouble("harga_jual") * qty;
                        item.put("subtotal", subtotal);
                        cartTotal += subtotal;
                        cartItems.add(item);
                    }
                    rs.close(); ps.close();
                } catch (Exception ignored) {}
            }
            conn.close();
        } catch (Exception ignored) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VEND.IO - Cart</title>
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

    <main class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h2 class="text-4xl font-[900] text-black uppercase mb-8 inline-block bg-white border-[4px] border-black px-4 py-2 brutal-btn">
            YOUR CART (<%= cartItems.size() %> ITEMS)
        </h2>

        <% if (cartItems.isEmpty()) { %>
        <div class="bg-white border-[4px] border-black p-16 brutal-shadow text-center">
            <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mx-auto mb-6 opacity-20">
                <circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
            </svg>
            <p class="font-[900] text-3xl uppercase text-black mb-6">YOUR CART IS EMPTY</p>
            <a href="index.jsp" class="bg-[#FACC15] border-[4px] border-black px-8 py-3 font-[900] text-black tracking-widest uppercase brutal-btn hover:bg-yellow-400 transition-colors inline-block">
                START SHOPPING
            </a>
        </div>
        <% } else { %>

        <div class="bg-black p-3 brutal-shadow">
            <div class="bg-white border-[4px] border-black">
                <!-- Items Table -->
                <div class="overflow-x-auto">
                    <table class="w-full">
                        <thead>
                            <tr class="border-b-[4px] border-black bg-gray-50">
                                <th class="py-4 px-6 text-left font-[900] uppercase tracking-wider text-sm">PRODUCT</th>
                                <th class="py-4 px-4 text-right font-[900] uppercase tracking-wider text-sm">PRICE</th>
                                <th class="py-4 px-6 text-center font-[900] uppercase tracking-wider text-sm">QTY</th>
                                <th class="py-4 px-4 text-right font-[900] uppercase tracking-wider text-sm">SUBTOTAL</th>
                                <th class="py-4 px-4 text-center font-[900] uppercase tracking-wider text-sm"></th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Map<String, Object> item : cartItems) {
                                int itemId = (Integer) item.get("id");
                                int itemQty = (Integer) item.get("qty");
                                int itemStok = (Integer) item.get("stok");
                            %>
                            <tr class="border-b-[2px] border-gray-200">
                                <!-- Product info -->
                                <td class="py-4 px-6">
                                    <div class="flex items-center gap-4">
                                        <div class="w-16 h-16 border-[3px] border-black overflow-hidden flex-shrink-0">
                                            <img src="<%= item.get("image") %>" alt="<%= item.get("nama") %>" class="w-full h-full object-cover">
                                        </div>
                                        <span class="font-[900] text-black uppercase text-sm"><%= item.get("nama") %></span>
                                    </div>
                                </td>
                                <!-- Price -->
                                <td class="py-4 px-4 text-right font-bold text-black whitespace-nowrap text-sm">
                                    Rp<%= String.format("%,.0f", (Double) item.get("harga")) %>
                                </td>
                                <!-- Qty controls -->
                                <td class="py-4 px-6">
                                    <form action="cart.jsp?action=update" method="POST" class="flex items-center justify-center gap-1">
                                        <input type="hidden" name="id" value="<%= itemId %>">
                                        <button type="submit" name="qty" value="<%= itemQty - 1 %>"
                                                class="bg-black text-white border-[2px] border-black w-8 h-8 font-[900] text-lg leading-none hover:bg-gray-800 transition-colors flex items-center justify-center">−</button>
                                        <span class="font-[900] text-black text-lg w-10 text-center"><%= itemQty %></span>
                                        <button type="submit" name="qty" value="<%= Math.min(itemQty + 1, itemStok) %>"
                                                class="bg-black text-white border-[2px] border-black w-8 h-8 font-[900] text-lg leading-none hover:bg-gray-800 transition-colors flex items-center justify-center">+</button>
                                    </form>
                                </td>
                                <!-- Subtotal -->
                                <td class="py-4 px-4 text-right font-[900] text-black whitespace-nowrap">
                                    Rp<%= String.format("%,.0f", (Double) item.get("subtotal")) %>
                                </td>
                                <!-- Remove -->
                                <td class="py-4 px-4 text-center">
                                    <a href="cart.jsp?action=remove&id=<%= itemId %>"
                                       class="text-red-500 font-[900] uppercase text-xs hover:text-red-700 border-[2px] border-red-300 px-2 py-1 hover:border-red-500 transition-colors"
                                       onclick="return confirm('Remove this item from cart?')">REMOVE</a>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>

                <!-- Cart Footer -->
                <div class="flex flex-col md:flex-row justify-between items-start md:items-center p-6 border-t-[4px] border-black gap-4">
                    <a href="cart.jsp?action=clear"
                       class="border-[3px] border-black px-4 py-2 font-[900] text-black uppercase text-sm brutal-btn hover:bg-red-100 transition-colors"
                       onclick="return confirm('Remove all items from cart?')">
                        CLEAR CART
                    </a>
                    <div class="flex flex-col md:flex-row items-end md:items-center gap-6">
                        <div class="text-right">
                            <p class="font-[900] text-sm uppercase text-gray-500 m-0 tracking-widest">TOTAL</p>
                            <p class="font-[900] text-4xl text-black m-0">Rp<%= String.format("%,.0f", cartTotal) %></p>
                        </div>
                        <a href="checkout.jsp" class="bg-[#FACC15] border-[4px] border-black px-8 py-4 font-[900] text-black text-xl tracking-widest uppercase brutal-btn hover:bg-yellow-400 transition-colors inline-block whitespace-nowrap">
                            CHECKOUT →
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <% } %>

        <div class="text-center mt-12 pb-10">
            <p class="font-bold text-gray-400 text-sm m-0">Developed by Dandy & Verly</p>
        </div>
    </main>

</body>
</html>
