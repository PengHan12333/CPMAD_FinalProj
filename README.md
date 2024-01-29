# FlavorFuse: Unifying Palates in Your Smart City

## Background  
FlavorFuse is a revolutionary app designed to harmonize Singapore's culinary landscape within the Smart Nation framework. Through seamless technology integration, FlavorFuse effortlessly connects citizens to the city's diverse food scene, promising an engaging and effortless dining experience.

## Objectives  
FlavorFuse aims to streamline dining, empower local businesses, foster culinary community engagement, prioritize user well-being, ensure effortless in-app ordering, and enhance convenience through personalized order history. The app envisions seamlessly connecting users with the vibrant food scene in Singapore's Smart Nation, creating a unified and delightful culinary journey.

## Key Functional Features
### 1. User Authentication:
   - Account management (login/logout/register/update username/update password/update profile picture functionalities). Includes login/register/profile/about us pages.
   - **Two-Factor Authentication (2FA) (Optional Challenging Bonus Feature):**
     - Implement a secondary authentication method using Flutter packages like firebase_messaging for SMS or email verification.
     - Use the pin_code_fields package for a secure and user-friendly PIN entry interface.

### 2. Home Page:
   - Central hub offering easy navigation to key app features and personalized content.

### 3. Restaurant Explorer:
   - Interactive map providing real-time updates on restaurant availability and other relevant information, utilizing the Google Places API.

### 4. Exclusive Discounts:
   - Encourage user engagement through a loyalty program with redeemable vouchers for exclusive discounts.

### 5. In-App Ordering:
   - Simplify the ordering process with clear item descriptions, prices, and quantity selection.
   - Provide a user-friendly interface for selecting items from the menu and placing orders seamlessly.

### 6. Order History:
   - Allow users to view order history so that they can reorder the dishes they want and view the receipt for each successful order.
   - **Data Visualization (Optional Challenging Bonus Feature):**
     - Utilize Flutter charting libraries like fl_chart or charts_flutter to create interactive graphs and charts.
     - Illustrate cost breakdowns and spending patterns, enhancing user understanding of their expenses.

## Data Source & Data Storage
### 1. Data Source:
   - Leverage the Google Places API for real-time and accurate information on nearby restaurants.

### 2. Data Storage:
   - Utilize Firebase for secure user authentication, personalized profiles, loyalty program, and order history.

## References
   1. [Google Places API](https://developers.google.com/maps/documentation/places/web-service/overview)
   2. [Firebase](https://firebase.google.com/)
