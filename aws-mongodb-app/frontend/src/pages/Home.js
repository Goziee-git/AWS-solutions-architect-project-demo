import React from 'react';
import { 
  Container, 
  Typography, 
  Box, 
  Button, 
  Grid, 
  Card, 
  CardContent 
} from '@mui/material';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Home = () => {
  const { isAuthenticated, user } = useAuth();

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Box textAlign="center" mb={6}>
        <Typography variant="h2" component="h1" gutterBottom>
          Welcome to MongoDB App
        </Typography>
        <Typography variant="h5" color="text.secondary" paragraph>
          A full-stack application with React, Node.js, and MongoDB
        </Typography>
        
        {isAuthenticated ? (
          <Typography variant="h6" color="primary">
            Welcome back, {user?.username}!
          </Typography>
        ) : (
          <Box sx={{ mt: 3 }}>
            <Button 
              variant="contained" 
              size="large" 
              component={Link} 
              to="/register"
              sx={{ mr: 2 }}
            >
              Get Started
            </Button>
            <Button 
              variant="outlined" 
              size="large" 
              component={Link} 
              to="/login"
            >
              Login
            </Button>
          </Box>
        )}
      </Box>

      <Grid container spacing={4}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h5" component="h2" gutterBottom>
                Modern Stack
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Built with React, Node.js, Express, and MongoDB for a complete 
                full-stack experience.
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h5" component="h2" gutterBottom>
                AWS Deployment
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Deployed on AWS with high availability across multiple 
                Availability Zones for reliability.
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h5" component="h2" gutterBottom>
                Secure & Scalable
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Features JWT authentication, secure API endpoints, and 
                scalable architecture patterns.
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Box textAlign="center" mt={6}>
        <Button 
          variant="contained" 
          size="large" 
          component={Link} 
          to="/products"
        >
          View Products
        </Button>
      </Box>
    </Container>
  );
};

export default Home;
