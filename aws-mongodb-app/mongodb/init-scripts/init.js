// MongoDB initialization script
// This script runs when the MongoDB container starts for the first time

// Switch to the application database
db = db.getSiblingDB('myapp');

// Create application user with read/write permissions
db.createUser({
  user: 'appuser',
  pwd: 'apppassword123',
  roles: [
    {
      role: 'readWrite',
      db: 'myapp'
    }
  ]
});

// Create indexes for better performance
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "username": 1 }, { unique: true });
db.products.createIndex({ "name": "text", "description": "text" });
db.products.createIndex({ "category": 1 });
db.products.createIndex({ "price": 1 });
db.products.createIndex({ "createdAt": -1 });

// Insert sample data
db.users.insertOne({
  username: 'admin',
  email: 'admin@example.com',
  password: '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukx.LrUpm', // password123
  firstName: 'Admin',
  lastName: 'User',
  role: 'admin',
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date()
});

db.products.insertMany([
  {
    name: 'Sample Laptop',
    description: 'High-performance laptop for development',
    price: 1299.99,
    category: 'electronics',
    stock: 10,
    images: [
      {
        url: 'https://via.placeholder.com/400x300/0066cc/ffffff?text=Laptop',
        alt: 'Sample Laptop'
      }
    ],
    specifications: {
      'CPU': 'Intel i7',
      'RAM': '16GB',
      'Storage': '512GB SSD'
    },
    tags: ['laptop', 'computer', 'electronics'],
    isActive: true,
    createdBy: ObjectId(),
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Programming Book',
    description: 'Learn modern web development',
    price: 49.99,
    category: 'books',
    stock: 25,
    images: [
      {
        url: 'https://via.placeholder.com/400x300/009900/ffffff?text=Book',
        alt: 'Programming Book'
      }
    ],
    specifications: {
      'Pages': '450',
      'Language': 'English',
      'Format': 'Paperback'
    },
    tags: ['programming', 'web development', 'education'],
    isActive: true,
    createdBy: ObjectId(),
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

print('Database initialized successfully!');
