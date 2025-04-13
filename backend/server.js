require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const session = require("express-session");


const app = express();
const PORT = process.env.PORT || 3000;

// CORS configuration
app.use(
  cors({
    origin: (origin, callback) => {
      console.log("Origin:", origin);
      if (!origin) return callback(null, true);

      if (
        origin.startsWith("http://localhost:") ||
        origin.startsWith("http://192.168.") ||
        origin.startsWith("http://10.0.") ||
        origin.startsWith("http://127.0.0.1:")
      ) {
        return callback(null, true);
      }

      callback(new Error("Not allowed by CORS"));
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"]
  })
);

app.use((req, res, next) => {
  res.header("Access-Control-Allow-Credentials", "true");
  next();
});

app.use(bodyParser.json());

// Session configuration
app.use(
  session({
    secret: "090078601",
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      secure: false,
      sameSite: "lax",
      maxAge: 1000 * 60 * 60 * 24
    }
  })
);

// MongoDB connection
mongoose.connect(
  "mongodb+srv://shaheencodecrafters:090078601@bhuttalaw.wnsr9.mongodb.net/?retryWrites=true&w=majority&appName=bhuttalaw",
  {
    useNewUrlParser: true,
    useUnifiedTopology: true
  }
);

mongoose.connection.on("connected", () => {
  console.log("Connected to MongoDB");
});
mongoose.connection.on("error", (err) => {
  console.error("MongoDB connection error:", err);
});

// User schema
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true, unique: true },
  password: { type: String, required: true }
});

const User = mongoose.model("User", userSchema);

// Order schema
const orderSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  productId: { type: String, required: true },
  locationName: { type: String, required: true },
  locationLong: { type: Number, required: true },
  locationLat: { type: Number, required: true },
  status: { type: String, default: "requested" },
  technicianId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    default: null
  },
  price: { type: Number, default: null },
  createdAt: { type: Date, default: Date.now }
});

const Order = mongoose.model("Order", orderSchema);

// Category schema
const categorySchema = new mongoose.Schema({
  name: { type: String, required: true },
  imageUrl: { type: String, required: true },
  cloudinaryId: { type: String, required: true }
});

const Category = mongoose.model("Category", categorySchema);

// Product schema
const productSchema = new mongoose.Schema({
  title: { type: String, required: true },
  price: { type: Number, required: true },
  categoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Category",
    required: true
  },
  productImage: { type: String, required: true },
  cloudinaryId: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const Product = mongoose.model("Product", productSchema);

// 1. Get user by ID endpoint
app.get("/api/user/:id", async (req, res) => {
  try {
    const userId = req.params.id;

    // Validate the userId format
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: "Invalid user ID format" });
    }

    // Find the user
    const user = await User.findById(userId).select("-password -__v");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json(user);
  } catch (error) {
    console.error("Error fetching user:", error);
    res.status(500).json({ message: "Error fetching user" });
  }
});

// 2. Update user email endpoint
app.put("/api/user/email/:id", async (req, res) => {
  try {
    const userId = req.params.id;
    const { email } = req.body;

    // Validate the userId format
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: "Invalid user ID format" });
    }

    // Check if email already exists
    const existingUser = await User.findOne({ email });
    if (existingUser && existingUser._id.toString() !== userId) {
      return res.status(400).json({ message: "Email already in use" });
    }

    // Update the email
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { email },
      { new: true }
    ).select("-password -__v");

    if (!updatedUser) {
      return res.status(404).json({ message: "User not found" });
    }

    res
      .status(200)
      .json({ message: "Email updated successfully", user: updatedUser });
  } catch (error) {
    console.error("Error updating email:", error);
    res.status(500).json({ message: "Error updating email" });
  }
});

// 3. Update user password endpoint
app.put("/api/user/password/:id", async (req, res) => {
  try {
    const userId = req.params.id;
    const { oldPassword, newPassword } = req.body;

    // Validate the userId format
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: "Invalid user ID format" });
    }

    // Find the user
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Verify old password
    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: "Old password is incorrect" });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await User.findByIdAndUpdate(userId, { password: hashedPassword });

    res.status(200).json({ message: "Password updated successfully" });
  } catch (error) {
    console.error("Error updating password:", error);
    res.status(500).json({ message: "Error updating password" });
  }
});

// Login Endpoint
app.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    req.session.userId = user._id;
    req.session.save((err) => {
      if (err) {
        console.error("Session save error:", err);
        return res.status(500).json({ message: "Session error" });
      }
      res.status(200).json({
        message: "Login successful",
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone
        }
      });
    });
  } catch (error) {
    res.status(500).json({ message: "Login error" });
  }
});

// Logout Endpoint - Updated with proper CORS and session handling
app.post(
  "/logout",
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (
        origin.startsWith("http://localhost:") ||
        origin.startsWith("http://192.168.") ||
        origin.startsWith("http://10.0.") ||
        origin.startsWith("http://127.0.0.1:")
      ) {
        return callback(null, true);
      }
      callback(new Error("Not allowed by CORS"));
    },
    credentials: true
  }),
  (req, res) => {
    req.session.destroy((err) => {
      if (err) {
        console.error("Logout error:", err);
        return res.status(500).json({ message: "Logout failed" });
      }
      res.clearCookie("connect.sid", {
        path: "/",
        httpOnly: true,
        secure: false,
        sameSite: "lax"
      });
      res.status(200).json({ message: "Logout successful" });
    });
  }
);

// Get orders by user ID endpoint
app.get("/api/my-orders/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    // Validate the userId format
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: "Invalid user ID format" });
    }

    // Optional: Verify the requested user ID matches the logged-in user
    if (req.session.userId && req.session.userId.toString() !== userId) {
      return res.status(403).json({ message: "Unauthorized access" });
    }

    // Find all orders for this user with populated details
    const orders = await Order.find({ userId })
      .populate({
        path: "productId",
        populate: {
          path: "categoryId",
          select: "name imageUrl"
        }
      })
      .populate("technicianId", "name email phone")
      .sort({ createdAt: -1 });

    if (!orders || orders.length === 0) {
      return res.status(404).json({ message: "No orders found for this user" });
    }

    res.status(200).json(orders);
  } catch (error) {
    console.error("Error fetching user orders:", error);
    res.status(500).json({ message: "Error fetching orders" });
  }
});

// Order creation endpoint
app.post("/api/orders", async (req, res) => {
  try {
    let userId = req.session.userId;

    if (!userId && req.body.userId) {
      userId = req.body.userId;
    }

    if (!userId) {
      console.log("No userId found in session or request body");
      return res.status(401).json({ message: "Unauthorized" });
    }

    const { productId, locationName, locationLong, locationLat } = req.body;

    const newOrder = new Order({
      userId: userId,
      productId,
      locationName,
      locationLong,
      locationLat
    });

    await newOrder.save();
    res
      .status(201)
      .json({ message: "Order created successfully", order: newOrder });
  } catch (error) {
    console.error("Error creating order:", error);
    res.status(500).json({ message: "Error creating order" });
  }
});

// Payment endpoint
app.post("/api/orders/payment", async (req, res) => {
  try {
    const { orderId, paymentMethod, paymentId } = req.body;

    // Validate input
    if (!mongoose.Types.ObjectId.isValid(orderId)) {
      return res.status(400).json({ message: "Invalid order ID" });
    }

    // Find and update the order
    const updatedOrder = await Order.findByIdAndUpdate(
      orderId,
      { 
        status: "paid",
        paymentMethod,
        paymentId: paymentMethod !== "cash" ? paymentId : null,
        paidAt: new Date()
      },
      { new: true }
    );

    if (!updatedOrder) {
      return res.status(404).json({ message: "Order not found" });
    }

    res.status(200).json({ message: "Payment processed successfully" });
  } catch (error) {
    console.error("Payment processing error:", error);
    res.status(500).json({ message: "Error processing payment" });
  }
});

// Get all categories endpoint
app.get("/api/categories", async (req, res) => {
  try {
    const categories = await Category.find();
    res.status(200).json(categories);
  } catch (error) {
    console.error("Error fetching categories:", error);
    res.status(500).json({ message: "Error fetching categories" });
  }
});

// Get single category by ID endpoint
app.get("/api/categories/:id", async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);
    if (!category) {
      return res.status(404).json({ message: "Category not found" });
    }
    res.status(200).json(category);
  } catch (error) {
    console.error("Error fetching category:", error);
    res.status(500).json({ message: "Error fetching category" });
  }
});

// Get all products
app.get("/api/products", async (req, res) => {
  try {
    const products = await Product.find().populate("categoryId");
    res.status(200).json(products);
  } catch (error) {
    console.error("Error fetching products:", error);
    res.status(500).json({ message: "Error fetching products" });
  }
});

// Get single product by ID
app.get("/api/products/:id", async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).populate(
      "categoryId"
    );
    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }
    res.status(200).json(product);
  } catch (error) {
    console.error("Error fetching product:", error);
    res.status(500).json({ message: "Error fetching product" });
  }
});

// Get products by category ID
app.get("/api/products/category/:categoryId", async (req, res) => {
  try {
    const products = await Product.find({ categoryId: req.params.categoryId });
    res.status(200).json(products);
  } catch (error) {
    console.error("Error fetching products by category:", error);
    res.status(500).json({ message: "Error fetching products by category" });
  }
});

// Create new product (protected route)
app.post("/api/products", async (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  try {
    const { title, price, categoryId, productImage, cloudinaryId } = req.body;

    const newProduct = new Product({
      title,
      price,
      categoryId,
      productImage,
      cloudinaryId
    });

    await newProduct.save();
    res
      .status(201)
      .json({ message: "Product created successfully", product: newProduct });
  } catch (error) {
    console.error("Error creating product:", error);
    res.status(500).json({ message: "Error creating product" });
  }
});

// Update product (protected route)
app.put("/api/products/:id", async (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  try {
    const updatedProduct = await Product.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    if (!updatedProduct) {
      return res.status(404).json({ message: "Product not found" });
    }

    res
      .status(200)
      .json({
        message: "Product updated successfully",
        product: updatedProduct
      });
  } catch (error) {
    console.error("Error updating product:", error);
    res.status(500).json({ message: "Error updating product" });
  }
});

// Delete product (protected route)
app.delete("/api/products/:id", async (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  try {
    const deletedProduct = await Product.findByIdAndDelete(req.params.id);

    if (!deletedProduct) {
      return res.status(404).json({ message: "Product not found" });
    }

    res.status(200).json({ message: "Product deleted successfully" });
  } catch (error) {
    console.error("Error deleting product:", error);
    res.status(500).json({ message: "Error deleting product" });
  }
});

// Add this with your other schema definitions
const sliderSchema = new mongoose.Schema({
  imageUrl: { type: String, required: true },
  cloudinaryId: { type: String, required: true }
});

const Slider = mongoose.model("Slider", sliderSchema);

// Add these endpoints with your other routes

// 1. Get all sliders
app.get("/api/sliders", async (req, res) => {
  try {
    const sliders = await Slider.find();
    res.status(200).json(sliders);
  } catch (error) {
    console.error("Error fetching sliders:", error);
    res.status(500).json({ message: "Error fetching sliders" });
  }
});

// 2. Get single slider by ID
app.get("/api/sliders/:id", async (req, res) => {
  try {
    const slider = await Slider.findById(req.params.id);
    if (!slider) {
      return res.status(404).json({ message: "Slider not found" });
    }
    res.status(200).json(slider);
  } catch (error) {
    console.error("Error fetching slider:", error);
    res.status(500).json({ message: "Error fetching slider" });
  }
});

// 3. Create new slider (protected route)
app.post("/api/sliders", async (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  try {
    const { imageUrl, cloudinaryId } = req.body;

    const newSlider = new Slider({
      imageUrl,
      cloudinaryId
    });

    await newSlider.save();
    res
      .status(201)
      .json({ message: "Slider created successfully", slider: newSlider });
  } catch (error) {
    console.error("Error creating slider:", error);
    res.status(500).json({ message: "Error creating slider" });
  }
});

// 4. Update slider (protected route)
app.put("/api/sliders/:id", async (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  try {
    const updatedSlider = await Slider.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    if (!updatedSlider) {
      return res.status(404).json({ message: "Slider not found" });
    }

    res
      .status(200)
      .json({ message: "Slider updated successfully", slider: updatedSlider });
  } catch (error) {
    console.error("Error updating slider:", error);
    res.status(500).json({ message: "Error updating slider" });
  }
});

// 5. Delete slider (protected route)
app.delete("/api/sliders/:id", async (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  try {
    const deletedSlider = await Slider.findByIdAndDelete(req.params.id);

    if (!deletedSlider) {
      return res.status(404).json({ message: "Slider not found" });
    }

    res.status(200).json({ message: "Slider deleted successfully" });
  } catch (error) {
    console.error("Error deleting slider:", error);
    res.status(500).json({ message: "Error deleting slider" });
  }
});

// Social Signup Endpoint
app.post("/social-signup", async (req, res) => {
  try {
    const { name, email, phone, provider } = req.body;

    // Check if user already exists
    let user = await User.findOne({ email });
    
    if (user) {
      // User exists, return success (or you might want to log them in directly)
      return res.status(200).json({
        message: "Login successful",
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone
        }
      });
    }

    // Create new user with social login
    const newUser = new User({
      name,
      email,
      phone,
      password: `${provider}_${Date.now()}`, // Dummy password
    });

    await newUser.save();

    // Create session (optional)
    req.session.userId = newUser._id;
    
    res.status(200).json({
      message: "Signup successful",
      user: {
        id: newUser._id,
        name: newUser.name,
        email: newUser.email,
        phone: newUser.phone
      }
    });
  } catch (error) {
    console.error("Social signup error:", error);
    res.status(500).json({ message: "Social signup error" });
  }
});

// Handle preflight requests
app.options("*", cors());

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
