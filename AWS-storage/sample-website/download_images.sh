#!/bin/bash

# Create images directory if it doesn't exist
mkdir -p images

# Download images using wget
# Paris - Eiffel Tower
wget -O images/paris.jpg "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80"

# Tokyo - City View
wget -O images/tokyo.jpg "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80"

# New York - City Skyline
wget -O images/new-york.jpg "https://images.unsplash.com/photo-1522083165195-3424ed129620?w=800&q=80"

# Sydney - Opera House
wget -O images/sydney.jpg "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80"

# About Us - Travel Team
wget -O images/about-us.jpg "https://images.unsplash.com/photo-1539635278303-d4002c07eae3?w=1200&q=80"

# Set proper permissions
chmod 644 images/*.jpg
