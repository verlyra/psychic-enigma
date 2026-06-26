<%@page import="jdbc.koneksi" %>
    <%@page import="java.sql.*" %>
        <%@page import="java.util.*" %>
            <%@page contentType="text/html" pageEncoding="UTF-8" %>
                <% boolean isLoggedIn=session.getAttribute("user_id") !=null; String userName=isLoggedIn ?
                    (String)session.getAttribute("nama_lengkap") : "Guest" ; Map<String, Integer> cartSession = (Map
                    <String, Integer>) session.getAttribute("cart");
                        int cartCount = 0;
                        if (cartSession != null) {
                        for (int qty : cartSession.values()) cartCount += qty;
                        }

                        String searchQuery = request.getParameter("search");
                        if (searchQuery == null) searchQuery = "";
                        %>
                        <!DOCTYPE html>
                        <html lang="en">

                        <head>
                            <meta charset="UTF-8">
                            <meta name="viewport" content="width=device-width, initial-scale=1.0">
                            <title>VEND.IO - Store</title>
                            <script src="https://cdn.tailwindcss.com"></script>
                            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css"
                                rel="stylesheet">
                            <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap"
                                rel="stylesheet">
                            <style>
                                body {
                                    font-family: 'Inter', sans-serif;
                                    background-color: #e5e7eb;
                                }

                                .brutal-shadow {
                                    box-shadow: 8px 8px 0px 0px rgba(0, 0, 0, 1);
                                }

                                .brutal-btn {
                                    box-shadow: 4px 4px 0px 0px rgba(0, 0, 0, 1);
                                }

                                .brutal-btn:active {
                                    box-shadow: 0px 0px 0px 0px rgba(0, 0, 0, 1);
                                    transform: translate(4px, 4px);
                                }

                                a {
                                    text-decoration: none;
                                }

                                .carousel-item img {
                                    height: 400px;
                                    width: 100%;
                                    object-fit: cover;
                                    background-color: #ffffff;
                                    border: 4px solid black;
                                }

                                .carousel-control-prev-icon,
                                .carousel-control-next-icon {
                                    background-color: black;
                                    border-radius: 50%;
                                    padding: 1.5rem;
                                    border: 3px solid white;
                                }
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
                                                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                                                    viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3"
                                                    stroke-linecap="round" stroke-linejoin="round">
                                                    <circle cx="9" cy="21" r="1"></circle>
                                                    <circle cx="20" cy="21" r="1"></circle>
                                                    <path
                                                        d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6">
                                                    </path>
                                                </svg>
                                            </div>
                                            <a href="index.jsp">
                                                <h1 class="text-3xl font-[900] italic tracking-tighter text-black m-0">
                                                    VEND.IO</h1>
                                            </a>
                                        </div>

                                        <!-- Search Form -->
                                        <form method="GET" action="index.jsp"
                                            class="flex-1 max-w-xl mx-8 hidden md:flex">
                                            <div class="relative w-full">
                                                <input type="text" name="search" value="<%= searchQuery %>"
                                                    placeholder="Search for items..."
                                                    class="w-full bg-white border-[3px] border-black py-3 pl-4 pr-12 font-[900] placeholder:text-gray-400 focus:outline-none">
                                                <button type="submit"
                                                    class="absolute right-0 top-0 h-full px-3 bg-black border-[3px] border-black hover:bg-gray-800 transition-colors">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"
                                                        viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3"
                                                        stroke-linecap="round" stroke-linejoin="round">
                                                        <circle cx="11" cy="11" r="8"></circle>
                                                        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                                                    </svg>
                                                </button>
                                            </div>
                                        </form>

                                        <!-- User & Cart -->
                                        <div class="flex items-center gap-4">
                                            <% if(isLoggedIn) { %>
                                                <div class="text-right hidden md:block">
                                                    <p
                                                        class="text-xs font-[900] text-black tracking-widest uppercase m-0">
                                                        HELLO,</p>
                                                    <p class="text-lg font-[900] text-black uppercase m-0">
                                                        <%= userName %>
                                                    </p>
                                                </div>
                                                <!-- Order History -->
                                                <a href="order_history.jsp"
                                                    class="bg-white border-[3px] border-black p-2 brutal-btn hover:bg-gray-100 transition-colors"
                                                    title="Order History">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                                                        viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3"
                                                        stroke-linecap="round" stroke-linejoin="round">
                                                        <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path>
                                                        <line x1="3" y1="6" x2="21" y2="6"></line>
                                                        <path d="M16 10a4 4 0 0 1-8 0"></path>
                                                    </svg>
                                                </a>
                                                <!-- Cart Icon -->
                                                <a href="cart.jsp"
                                                    class="relative bg-white border-[3px] border-black p-2 brutal-btn hover:bg-gray-100 transition-colors"
                                                    title="Cart">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                                                        viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3"
                                                        stroke-linecap="round" stroke-linejoin="round">
                                                        <circle cx="9" cy="21" r="1"></circle>
                                                        <circle cx="20" cy="21" r="1"></circle>
                                                        <path
                                                            d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6">
                                                        </path>
                                                    </svg>
                                                    <% if (cartCount> 0) { %>
                                                        <span
                                                            class="absolute -top-2 -right-2 bg-red-500 text-white text-xs font-[900] min-w-[20px] h-5 flex items-center justify-center border-[2px] border-black px-1 leading-none">
                                                            <%= cartCount %>
                                                        </span>
                                                        <% } %>
                                                </a>
                                                <!-- Logout -->
                                                <a href="logout.jsp"
                                                    class="bg-white border-[3px] border-black p-2 brutal-btn hover:bg-red-500 hover:text-white transition-colors"
                                                    title="Logout">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                                                        viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                                        stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                                        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                                                        <polyline points="16 17 21 12 16 7"></polyline>
                                                        <line x1="21" y1="12" x2="9" y2="12"></line>
                                                    </svg>
                                                </a>
                                                <% } else { %>
                                                    <a href="login.jsp"
                                                        class="bg-white border-[3px] border-black px-4 py-2 font-[900] text-black tracking-widest uppercase brutal-btn hover:bg-gray-100 transition-colors">LOGIN</a>
                                                    <a href="register.jsp"
                                                        class="bg-[#4ADE80] border-[3px] border-black px-4 py-2 font-[900] text-black tracking-widest uppercase brutal-btn hover:bg-green-500 transition-colors">REGISTER</a>
                                                    <% } %>
                                        </div>
                                    </div>
                                </div>
                            </header>

                            <!-- Main Content -->
                            <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">

                                <!-- Carousel (hidden during search) -->
                                <% if (searchQuery.isEmpty()) { %>
                                    <div class="mb-12">
                                        <div id="promoCarousel"
                                            class="carousel slide brutal-shadow border-[4px] border-black bg-white"
                                            data-bs-ride="carousel">
                                            <div class="carousel-indicators mb-2">
                                                <button type="button" data-bs-target="#promoCarousel"
                                                    data-bs-slide-to="0" class="active"
                                                    style="background-color: black; height: 10px; width: 30px;"></button>
                                                <button type="button" data-bs-target="#promoCarousel"
                                                    data-bs-slide-to="1"
                                                    style="background-color: black; height: 10px; width: 30px;"></button>
                                                <button type="button" data-bs-target="#promoCarousel"
                                                    data-bs-slide-to="2"
                                                    style="background-color: black; height: 10px; width: 30px;"></button>
                                                <button type="button" data-bs-target="#promoCarousel"
                                                    data-bs-slide-to="3"
                                                    style="background-color: black; height: 10px; width: 30px;"></button>
                                                <button type="button" data-bs-target="#promoCarousel"
                                                    data-bs-slide-to="4"
                                                    style="background-color: black; height: 10px; width: 30px;"></button>
                                            </div>
                                            <div class="carousel-inner">
                                                <div class="carousel-item active">
                                                    <img src="https://i.pinimg.com/736x/1f/69/bd/1f69bd48c070745f02939183534ae617.jpg"
                                                        alt="Promo 1">
                                                </div>
                                                <div class="carousel-item">
                                                    <img src="https://i.pinimg.com/736x/cd/fe/a7/cdfea77d47292b8fd71bac4f2d073f46.jpg"
                                                        alt="Promo 2">
                                                </div>
                                                <div class="carousel-item">
                                                    <img src="https://i.pinimg.com/736x/31/ff/05/31ff05f8a59f0d1457cfe231c89bdbdb.jpg"
                                                        alt="Flash Sale">
                                                </div>
                                                <div class="carousel-item">
                                                    <img src="https://i.pinimg.com/736x/f1/23/0d/f1230dc057b03ca5ce44ad2065166210.jpg"
                                                        alt="Promo 4">
                                                </div>
                                                <div class="carousel-item">
                                                    <img src="https://i.pinimg.com/736x/2e/6e/bd/2e6ebde4748cbc2ab35c88008cdd6014.jpg"
                                                        alt="Promo 5">
                                                </div>
                                            </div>
                                            <button class="carousel-control-prev" type="button"
                                                data-bs-target="#promoCarousel" data-bs-slide="prev">
                                                <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                                                <span class="visually-hidden">Previous</span>
                                            </button>
                                            <button class="carousel-control-next" type="button"
                                                data-bs-target="#promoCarousel" data-bs-slide="next">
                                                <span class="carousel-control-next-icon" aria-hidden="true"></span>
                                                <span class="visually-hidden">Next</span>
                                            </button>
                                        </div>
                                    </div>
                                    <% } else { %>
                                        <!-- Search result banner -->
                                        <div class="mb-8 flex items-center gap-4">
                                            <div
                                                class="bg-white border-[4px] border-black px-6 py-3 brutal-shadow inline-flex items-center gap-4">
                                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"
                                                    viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3"
                                                    stroke-linecap="round" stroke-linejoin="round">
                                                    <circle cx="11" cy="11" r="8"></circle>
                                                    <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                                                </svg>
                                                <span class="font-[900] text-lg uppercase">RESULTS FOR: "<%= searchQuery
                                                        %>"</span>
                                                <a href="index.jsp"
                                                    class="bg-black text-white border-[2px] border-black px-3 py-1 font-[900] text-xs uppercase hover:bg-gray-800 transition-colors">✕
                                                    CLEAR</a>
                                            </div>
                                        </div>
                                        <% } %>

                                            <h3
                                                class="text-3xl font-[900] text-black uppercase mb-8 inline-block bg-white border-[4px] border-black px-4 py-2 brutal-btn">
                                                <% if (!searchQuery.isEmpty()) { %>SEARCH RESULTS<% } else { %>ALL ITEMS
                                                        <% } %>
                                            </h3>

                                            <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-6 md:gap-8">
                                                <% String sqlSearch="SELECT * FROM master_product"
                                                    + " WHERE nama_produk LIKE ? OR merk LIKE ?" + " ORDER BY id DESC" ;
                                                    String sqlAll="SELECT * FROM master_product ORDER BY id DESC" ;
                                                    String
                                                    placeholder="https://via.placeholder.com/200/ffffff/000000?text=NO+IMAGE"
                                                    ; try { koneksi k=new koneksi(); Connection conn=k.bukaKoneksi(); if
                                                    (conn !=null) { PreparedStatement pstmt; if (!searchQuery.isEmpty())
                                                    { pstmt=conn.prepareStatement(sqlSearch); pstmt.setString(1, "%" +
                                                    searchQuery + "%" ); pstmt.setString(2, "%" + searchQuery + "%" ); }
                                                    else { pstmt=conn.prepareStatement(sqlAll); } ResultSet
                                                    rs=pstmt.executeQuery(); boolean hasData=false; while (rs.next()) {
                                                    hasData=true; String img=rs.getString("image_url"); if (img==null ||
                                                    img.trim().isEmpty()) { img=placeholder; } int
                                                    productId=rs.getInt("id"); int stok=rs.getInt("stok"); %>

                                                    <!-- Product Card -->
                                                    <a href="product.jsp?id=<%= productId %>" class="block">
                                                        <div
                                                            class="bg-white border-[4px] border-black p-4 brutal-btn flex flex-col h-full hover:-translate-y-2 transition-transform duration-200">
                                                            <div
                                                                class="aspect-square border-[3px] border-black mb-4 overflow-hidden bg-gray-100">
                                                                <img src="<%= img %>" alt="Product"
                                                                    class="w-full h-full object-cover">
                                                            </div>
                                                            <h4
                                                                class="font-[900] text-black text-lg uppercase leading-tight mb-2 flex-1">
                                                                <%= rs.getString("nama_produk") %>
                                                            </h4>
                                                            <div class="mt-auto">
                                                                <p class="font-[900] text-2xl text-black m-0">Rp<%=
                                                                        String.format("%,.0f",
                                                                        rs.getDouble("harga_jual")) %>
                                                                </p>
                                                            </div>
                                                        </div>
                                                    </a>

                                                    <% } if(!hasData) { %>
                                                        <div class="col-span-full py-20 text-center">
                                                            <div
                                                                class="bg-white border-[4px] border-black inline-block p-10 brutal-shadow">
                                                                <p
                                                                    class="font-[900] text-2xl text-black uppercase tracking-widest m-0">
                                                                    No Items Found.</p>
                                                            </div>
                                                        </div>
                                                        <% } rs.close(); pstmt.close(); conn.close(); } }
                                                            catch(Exception e) { %>
                                                            <div
                                                                class="col-span-full py-12 text-center text-red-500 font-bold">
                                                                <p>Error: <%= e.getMessage() %>
                                                                </p>
                                                            </div>
                                                            <% } %>
                                            </div>

                                            <div class="text-center mt-20 pb-10">
                                                <p class="font-bold text-gray-400 text-sm m-0">Developed by Dandy &
                                                    Verly</p>
                                            </div>
                            </main>

                            <script
                                src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
                        </body>

                        </html>