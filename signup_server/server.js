const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const session = require('express-session'); // Add session middleware
const uniqueValidator = require('mongoose-unique-validator');

const app = express();
const PORT = 3000;

app.use(cors({
  origin: 'http://localhost:5500', // Allow frontend to access the backend
  credentials: true, // Allow cookies to be sent
}));
app.use(bodyParser.json());

// Session configuration
app.use(session({
  secret: 'your-secret-key', // Replace with a secure secret key
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: false, // Set to true if using HTTPS
    maxAge: 1000 * 60 * 60 * 24, // Session expires in 1 day
  },
}));

// MongoDB connection
mongoose.connect('mongodb+srv://shaheencodecrafters:090078601@bhuttalaw.wnsr9.mongodb.net/?retryWrites=true&w=majority&appName=bhuttalaw', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// User schema
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true, unique: true },
  password: { type: String, required: true },
});

userSchema.plugin(uniqueValidator);

const User = mongoose.model('User', userSchema);

// Login endpoint
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).send('User not found');
    }

    // Compare passwords
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(400).send('Invalid password');
    }

    // Create session
    req.session.userId = user._id; // Store user ID in session
    res.status(200).json({ message: 'Login successful', user: { name: user.name, email: user.email } });
  } catch (error) {
    console.error(error);
    res.status(500).send('Error logging in');
  }
});

// Logout endpoint
app.post('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).send('Error logging out');
    }
    res.clearCookie('connect.sid'); // Clear session cookie
    res.status(200).send('Logout successful');
  });
});

// Protected route example
app.get('/profile', (req, res) => {
  if (!req.session.userId) {
    return res.status(401).send('Unauthorized');
  }
  res.status(200).send('Welcome to your profile');
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});