import { useState, useEffect, useRef } from 'react'
import './App.css'

function App() {
  const [showPromoBanner, setShowPromoBanner] = useState(false)
  const [showCookieBanner, setShowCookieBanner] = useState(true)
  const [cookiesAccepted, setCookiesAccepted] = useState(false)
  const [showDatePicker, setShowDatePicker] = useState(false)
  const [showPassengerSelector, setShowPassengerSelector] = useState(false)
  const [showFromDropdown, setShowFromDropdown] = useState(false)
  const [showToDropdown, setShowToDropdown] = useState(false)
  const [departDate, setDepartDate] = useState('')
  const [returnDate, setReturnDate] = useState('')
  const [adults, setAdults] = useState(1)
  const [minors, setMinors] = useState(0)
  const [fromLocation, setFromLocation] = useState('')
  const [toLocation, setToLocation] = useState('')
  const [fromSearchTerm, setFromSearchTerm] = useState('')
  const [toSearchTerm, setToSearchTerm] = useState('')
  const [currentMonth, setCurrentMonth] = useState(new Date())
  const datePickerRef = useRef(null)
  const passengerSelectorRef = useRef(null)
  const fromDropdownRef = useRef(null)
  const toDropdownRef = useRef(null)

  // Sample location data
  const locations = [
    { city: 'New York', code: 'JFK', country: 'United States' },
    { city: 'London', code: 'LHR', country: 'United Kingdom' },
    { city: 'Tokyo', code: 'NRT', country: 'Japan' },
    { city: 'Paris', code: 'CDG', country: 'France' },
    { city: 'Sydney', code: 'SYD', country: 'Australia' },
    { city: 'Dubai', code: 'DXB', country: 'UAE' },
    { city: 'Singapore', code: 'SIN', country: 'Singapore' },
    { city: 'Hong Kong', code: 'HKG', country: 'China' },
    { city: 'Amsterdam', code: 'AMS', country: 'Netherlands' },
    { city: 'Frankfurt', code: 'FRA', country: 'Germany' },
    { city: 'Madrid', code: 'MAD', country: 'Spain' },
    { city: 'Rome', code: 'FCO', country: 'Italy' },
    { city: 'Barcelona', code: 'BCN', country: 'Spain' },
    { city: 'Milan', code: 'MXP', country: 'Italy' },
    { city: 'Vienna', code: 'VIE', country: 'Austria' },
    { city: 'Prague', code: 'PRG', country: 'Czech Republic' },
    { city: 'Budapest', code: 'BUD', country: 'Hungary' },
    { city: 'Warsaw', code: 'WAW', country: 'Poland' },
    { city: 'Stockholm', code: 'ARN', country: 'Sweden' },
    { city: 'Copenhagen', code: 'CPH', country: 'Denmark' },
    { city: 'Oslo', code: 'OSL', country: 'Norway' },
    { city: 'Helsinki', code: 'HEL', country: 'Finland' },
    { city: 'Moscow', code: 'SVO', country: 'Russia' },
    { city: 'Istanbul', code: 'IST', country: 'Turkey' },
    { city: 'Cairo', code: 'CAI', country: 'Egypt' },
    { city: 'Nairobi', code: 'NBO', country: 'Kenya' },
    { city: 'Cape Town', code: 'CPT', country: 'South Africa' },
    { city: 'Lagos', code: 'LOS', country: 'Nigeria' },
    { city: 'Mumbai', code: 'BOM', country: 'India' },
    { city: 'Delhi', code: 'DEL', country: 'India' },
    { city: 'Bangkok', code: 'BKK', country: 'Thailand' },
    { city: 'Seoul', code: 'ICN', country: 'South Korea' },
    { city: 'Beijing', code: 'PEK', country: 'China' },
    { city: 'Shanghai', code: 'PVG', country: 'China' },
    { city: 'Toronto', code: 'YYZ', country: 'Canada' },
    { city: 'Vancouver', code: 'YVR', country: 'Canada' },
    { city: 'Montreal', code: 'YUL', country: 'Canada' },
    { city: 'Mexico City', code: 'MEX', country: 'Mexico' },
    { city: 'São Paulo', code: 'GRU', country: 'Brazil' },
    { city: 'Buenos Aires', code: 'EZE', country: 'Argentina' },
    { city: 'Lima', code: 'LIM', country: 'Peru' },
    { city: 'Bogotá', code: 'BOG', country: 'Colombia' }
  ]

  const handleAcceptCookies = () => {
    setCookiesAccepted(true)
    setShowCookieBanner(false)
    localStorage.setItem('cookiesAccepted', 'true')
  }

  const filterLocations = (searchTerm) => {
    if (!searchTerm) return locations
    return locations.filter(location => 
      location.city.toLowerCase().includes(searchTerm.toLowerCase()) ||
      location.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      location.country.toLowerCase().includes(searchTerm.toLowerCase())
    )
  }

  const handleLocationSelect = (location, type) => {
    if (type === 'from') {
      setFromLocation(`${location.city} (${location.code})`)
      setShowFromDropdown(false)
      setFromSearchTerm('')
    } else {
      setToLocation(`${location.city} (${location.code})`)
      setShowToDropdown(false)
      setToSearchTerm('')
    }
  }

  const handleCloseCookies = () => {
    setShowCookieBanner(false)
  }

  // Close dropdowns when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (datePickerRef.current && !datePickerRef.current.contains(event.target)) {
        setShowDatePicker(false)
      }
      if (passengerSelectorRef.current && !passengerSelectorRef.current.contains(event.target)) {
        setShowPassengerSelector(false)
      }
      if (fromDropdownRef.current && !fromDropdownRef.current.contains(event.target)) {
        setShowFromDropdown(false)
      }
      if (toDropdownRef.current && !toDropdownRef.current.contains(event.target)) {
        setShowToDropdown(false)
      }
    }

    if (showDatePicker || showPassengerSelector || showFromDropdown || showToDropdown) {
      document.addEventListener('mousedown', handleClickOutside)
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [showDatePicker, showPassengerSelector, showFromDropdown, showToDropdown])

  const formatDate = (date) => {
    if (!date) return ''
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric' 
    })
  }

  const getDaysInMonth = (date) => {
    try {
      const year = date.getFullYear()
      const month = date.getMonth()
      const firstDay = new Date(year, month, 1)
      const lastDay = new Date(year, month + 1, 0)
      const daysInMonth = lastDay.getDate()
      const startingDay = firstDay.getDay()
      
      const days = []
      for (let i = 0; i < startingDay; i++) {
        days.push(null)
      }
      for (let i = 1; i <= daysInMonth; i++) {
        days.push(new Date(year, month, i))
      }
      return days
    } catch (error) {
      console.error('Error in getDaysInMonth:', error)
      return []
    }
  }

  const handleDateSelect = (date) => {
    try {
      if (!departDate || (departDate && returnDate)) {
        setDepartDate(date)
        setReturnDate('')
      } else {
        if (date > departDate) {
          setReturnDate(date)
          setShowDatePicker(false)
        } else {
          setDepartDate(date)
          setReturnDate('')
        }
      }
    } catch (error) {
      console.error('Error in handleDateSelect:', error)
    }
  }

  const isDateInRange = (date) => {
    try {
      if (!departDate || !returnDate || !date) return false
      return date >= departDate && date <= returnDate
    } catch (error) {
      console.error('Error in isDateInRange:', error)
      return false
    }
  }

  const isSelectedDate = (date) => {
    try {
      if (!date) return false
      return (departDate && date.getTime() === departDate.getTime()) || 
             (returnDate && date.getTime() === returnDate.getTime())
    } catch (error) {
      console.error('Error in isSelectedDate:', error)
      return false
    }
  }

  const nextMonth = () => {
    try {
      setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1))
    } catch (error) {
      console.error('Error in nextMonth:', error)
    }
  }

  const prevMonth = () => {
    try {
      setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1))
    } catch (error) {
      console.error('Error in prevMonth:', error)
    }
  }

  return (
    <div className="app">
      {/* Header/Navigation */}
      <header className="header">
        <div className="header-content">
          <div className="logo">
            <img src="/images/logo.png" alt="Ibwangi travel logo" style={{ height: '160px', width: 'auto' }} />
          </div>
          <nav className="nav-links">
            <a href="#flights">Flights</a>
            <a href="#hotels">Hotels</a>
            <a href="#packages">Packages</a>
            <a href="#signin">Sign in</a>
          </nav>
          <button className="signup-btn">Sign up</button>
        </div>
      </header>

      {/* Main Content */}
      <main className="main-content">
        {/* Background World Map */}
        <div className="map-background"></div>
        
        {/* Slogan */}
        <h1 className="slogan" style={{ position: 'relative', zIndex: 1 }}>
          <span className="blue-text">It's more than</span>
          <span className="purple-text"> just a trip.</span>
        </h1>

        {/* Trip Type Selection */}
        <div className="trip-type-selection">
          <label className="radio-option">
            <input type="radio" name="tripType" value="roundTrip" defaultChecked />
            <span className="radio-custom"></span>
            Round trip
          </label>
          <label className="radio-option">
            <input type="radio" name="tripType" value="oneWay" />
            <span className="radio-custom"></span>
            One way
          </label>
        </div>

        {/* Flight Search Form */}
        <div className="search-form">
          <div className="form-row">
            <div className="input-group location-selector-container" ref={fromDropdownRef}>
              <span className="icon">✈️</span>
              <input 
                type="text" 
                placeholder="From where?" 
                value={fromLocation}
                onChange={(e) => setFromSearchTerm(e.target.value)}
                onClick={() => setShowFromDropdown(!showFromDropdown)}
                readOnly
              />
              {showFromDropdown && (
                <div className="location-dropdown">
                  <div className="location-search">
                    <input 
                      type="text" 
                      placeholder="Search cities, airports, or countries..."
                      value={fromSearchTerm}
                      onChange={(e) => setFromSearchTerm(e.target.value)}
                      autoFocus
                    />
                  </div>
                  <div className="location-list">
                    {filterLocations(fromSearchTerm).map((location, index) => (
                      <div 
                        key={index} 
                        className="location-item"
                        onClick={() => handleLocationSelect(location, 'from')}
                      >
                        <div className="location-main">
                          <span className="location-city">{location.city}</span>
                          <span className="location-code">({location.code})</span>
                        </div>
                        <span className="location-country">{location.country}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
            <div className="input-group location-selector-container" ref={toDropdownRef}>
              <span className="icon">✈️</span>
              <input 
                type="text" 
                placeholder="Where to?" 
                value={toLocation}
                onChange={(e) => setToSearchTerm(e.target.value)}
                onClick={() => setShowToDropdown(!showToDropdown)}
                readOnly
              />
              {showToDropdown && (
                <div className="location-dropdown">
                  <div className="location-search">
                    <input 
                      type="text" 
                      placeholder="Search cities, airports, or countries..."
                      value={toSearchTerm}
                      onChange={(e) => setToSearchTerm(e.target.value)}
                      autoFocus
                    />
                  </div>
                  <div className="location-list">
                    {filterLocations(toSearchTerm).map((location, index) => (
                      <div 
                        key={index} 
                        className="location-item"
                        onClick={() => handleLocationSelect(location, 'to')}
                      >
                        <div className="location-main">
                          <span className="location-city">{location.city}</span>
                          <span className="location-code">({location.code})</span>
                        </div>
                        <span className="location-country">{location.country}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
            <div className="input-group date-picker-container" ref={datePickerRef}>
              <span className="icon">📅</span>
              <input 
                type="text" 
                placeholder="Depart - Return" 
                readOnly
                onClick={() => {
                  console.log('Date picker clicked')
                  setShowDatePicker(!showDatePicker)
                }}
                value={departDate && returnDate ? `${formatDate(departDate)} - ${formatDate(returnDate)}` : ''}
              />
              {showDatePicker && (
                <div className="date-picker">
                  <div className="date-picker-header">
                    <button onClick={prevMonth}>&lt;</button>
                    <span>{currentMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}</span>
                    <button onClick={nextMonth}>&gt;</button>
                  </div>
                  <div className="date-picker-grid">
                    <div className="weekdays">
                      <span>Su</span>
                      <span>Mo</span>
                      <span>Tu</span>
                      <span>We</span>
                      <span>Th</span>
                      <span>Fr</span>
                      <span>Sa</span>
                    </div>
                    <div className="days">
                      {getDaysInMonth(currentMonth).map((date, index) => (
                        <button
                          key={index}
                          className={`day ${!date ? 'empty' : ''} ${isSelectedDate(date) ? 'selected' : ''} ${isDateInRange(date) ? 'in-range' : ''}`}
                          onClick={() => {
                            console.log('Date clicked:', date)
                            date && handleDateSelect(date)
                          }}
                          disabled={!date}
                        >
                          {date ? date.getDate() : ''}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              )}
            </div>
            <div className="input-group passenger-selector-container" ref={passengerSelectorRef}>
              <span className="icon">👤</span>
              <input 
                type="text" 
                placeholder="1 adult" 
                readOnly
                onClick={() => setShowPassengerSelector(!showPassengerSelector)}
                value={`${adults} adult${adults > 1 ? 's' : ''}${minors > 0 ? `, ${minors} minor${minors > 1 ? 's' : ''}` : ''}`}
              />
              {showPassengerSelector && (
                <div className="passenger-selector">
                  <div className="passenger-row">
                    <div className="passenger-label">
                      <span>Adults</span>
                      <small>Ages 13+</small>
                    </div>
                    <div className="passenger-controls">
                      <button 
                        onClick={() => setAdults(Math.max(1, adults - 1))}
                        disabled={adults <= 1}
                      >
                        -
                      </button>
                      <span>{adults}</span>
                      <button 
                        onClick={() => setAdults(adults + 1)}
                        disabled={adults >= 9}
                      >
                        +
                      </button>
                    </div>
                  </div>
                  <div className="passenger-row">
                    <div className="passenger-label">
                      <span>Minors</span>
                      <small>Ages 0-12</small>
                    </div>
                    <div className="passenger-controls">
                      <button 
                        onClick={() => setMinors(Math.max(0, minors - 1))}
                        disabled={minors <= 0}
                      >
                        -
                      </button>
                      <span>{minors}</span>
                      <button 
                        onClick={() => setMinors(minors + 1)}
                        disabled={minors >= 9}
                      >
                        +
                      </button>
                    </div>
                  </div>
                  <div className="passenger-total">
                    <span>Total: {adults + minors} passenger{adults + minors > 1 ? 's' : ''}</span>
                  </div>
                </div>
              )}
            </div>
            <button className="search-btn">Search</button>
          </div>
        </div>
      </main>

      {/* Flight Deals Section */}
      <section className="flight-deals">
        <div className="section-header">
          <h2>Find your next adventure with these flight deals</h2>
          <a href="#all-deals" className="all-link">All →</a>
        </div>
        <div className="deals-grid">
          <div className="deal-card">
            <div className="deal-image shanghai"></div>
            <div className="deal-content">
              <h3>The Bund, Shanghai</h3>
              <p>China's most international city</p>
              <div className="deal-price">$598</div>
            </div>
          </div>
          <div className="deal-card">
            <div className="deal-image sydney"></div>
            <div className="deal-content">
              <h3>Sydney Opera House, Sydney</h3>
              <p>Take a stroll along the famous harbor</p>
              <div className="deal-price">$981</div>
            </div>
          </div>
          <div className="deal-card">
            <div className="deal-image kyoto"></div>
            <div className="deal-content">
              <h3>Kōdaiji Temple, Kyoto</h3>
              <p>Step back in time in the Gion district</p>
              <div className="deal-price">$633</div>
            </div>
          </div>
          <div className="deal-card">
            <div className="deal-image kenya"></div>
            <div className="deal-content">
              <h3>Tsavo East National Park, Kenya</h3>
              <p>Named after the Tsavo River, and opened in April 1984, Tsavo East National Park is one of the oldest parks in Kenya. It is located in the semi-arid Taru Desert.</p>
              <div className="deal-price">$1,248</div>
            </div>
          </div>
        </div>
      </section>

      {/* Unique Stays Section */}
      <section className="unique-stays">
        <div className="section-header">
          <h2>Explore unique places to stay</h2>
          <a href="#all-stays" className="all-link">All→</a>
        </div>
        <div className="stays-grid">
          <div className="stay-card">
            <div className="stay-image maldives"></div>
            <div className="stay-content">
              <h3>Stay among the atolls in Maldives</h3>
              <p>From the 2nd century AD, the islands were known as the 'Money Isles' due to the abundance of cowry shells, a currency of the early ages.</p>
            </div>
          </div>
          <div className="stay-card">
            <div className="stay-image morocco"></div>
            <div className="stay-content">
              <h3>Experience the Ourika Valley in Morocco</h3>
              <p>Morocco's Hispano-Moorish architecture blends influences from Berber culture, Spain, and contemporary artistic currents in the Middle East.</p>
            </div>
          </div>
          <div className="stay-card">
            <div className="stay-image mongolia"></div>
            <div className="stay-content">
              <h3>Live traditionally in Mongolia</h3>
              <p>Traditional Mongolian yurts consists of an angled latticework of wood or bamboo for walls, ribs, and a wheel.</p>
            </div>
          </div>
        </div>
        <div className="explore-more">
          <button className="explore-btn">Explore more stays</button>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="testimonials">
        <div className="section-header">
          <h2>What Ibwangi travel users are saying</h2>
        </div>
        <div className="testimonials-grid">
          <div className="testimonial-card">
            <div className="user-profile">
              <div className="profile-pic"></div>
              <div className="user-info">
                <h4>Yifei Chen</h4>
                <span>Seoul, South Korea</span>
                <span>April 2019</span>
              </div>
            </div>
            <div className="rating">★★★★★</div>
            <p>"I've been using Ibwangi travel for all my international flights. The booking process is so smooth and their customer support is amazing. Highly recommend!"</p>
            <a href="#read-more" className="read-more">read more...</a>
          </div>
          <div className="testimonial-card">
            <div className="user-profile">
              <div className="profile-pic"></div>
              <div className="user-info">
                <h4>Kaori Yamaguchi</h4>
                <span>Honolulu, Hawaii</span>
                <span>February 2017</span>
              </div>
            </div>
            <div className="rating">★★★★☆</div>
            <p>"Found great deals on flights to Hawaii through Ibwangi travel. The website is easy to navigate and I saved a lot of money on my trip."</p>
            <a href="#read-more" className="read-more">read more...</a>
          </div>
          <div className="testimonial-card">
            <div className="user-profile">
              <div className="profile-pic"></div>
              <div className="user-info">
                <h4>Anthony Lewis</h4>
                <span>Berlin, Germany</span>
                <span>April 2019</span>
              </div>
            </div>
            <div className="rating">★★★★★</div>
            <p>"Love browsing through Ibwangi travel's deals. The interface is clean and I always find something interesting. Will definitely recommend to friends!"</p>
            <a href="#read-more" className="read-more">read more...</a>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="footer-content">
          <div className="footer-section">
            <div className="footer-logo">
              <img src="/images/logo.png" alt="Ibwangi travel logo" style={{ height: '160px', width: 'auto', filter: 'brightness(0) invert(1)' }} />
            </div>
          </div>
          <div className="footer-section">
            <h4>About</h4>
            <ul>
              <li><a href="#about">About Ibwangi travel</a></li>
              <li><a href="#how-it-works">How it works</a></li>
              <li><a href="#careers">Careers</a></li>
              <li><a href="#press">Press</a></li>
              <li><a href="#blog">Blog</a></li>
              <li><a href="#forum">Forum</a></li>
            </ul>
          </div>
          <div className="footer-section">
            <h4>Partner with us</h4>
            <ul>
              <li><a href="#partnerships">Partnership programs</a></li>
              <li><a href="#affiliate">Affiliate program</a></li>
              <li><a href="#connectivity">Connectivity partners</a></li>
              <li><a href="#promotions">Promotions and events</a></li>
              <li><a href="#integrations">Integrations</a></li>
              <li><a href="#community">Community</a></li>
              <li><a href="#loyalty">Loyalty program</a></li>
            </ul>
          </div>
          <div className="footer-section">
            <h4>Support</h4>
            <ul>
              <li><a href="#help">Help Center</a></li>
              <li><a href="#contact">Contact us</a></li>
              <li><a href="#privacy">Privacy policy</a></li>
              <li><a href="#terms">Terms of service</a></li>
              <li><a href="#trust">Trust and safety</a></li>
              <li><a href="#accessibility">Accessibility</a></li>
            </ul>
          </div>
          <div className="footer-section">
            <h4>Get the app</h4>
            <p>Ibwangi travel for Android</p>
            <p>Ibwangi travel for iOS</p>
            <p>Mobile site</p>
          </div>
        </div>
        <div className="footer-bottom">
          <div className="social-links">
            <a href="#instagram">📷</a>
            <a href="#twitter">🐦</a>
            <a href="#facebook">📘</a>
          </div>
          <div className="copyright">© 2020 Ibwangi travel incorporated</div>
        </div>
      </footer>

      {/* Cookie Consent Banner */}
      {showCookieBanner && !cookiesAccepted && (
        <div className="cookie-banner">
          <div className="cookie-content">
            <button 
              className="close-btn"
              onClick={handleCloseCookies}
            >
              ✕
            </button>
            <p>By using our site, you agree to eat our cookies.</p>
            <div className="cookie-actions">
              <button className="accept-btn" onClick={handleAcceptCookies}>
                Accept cookies.
              </button>
              <a href="#settings" className="settings-link">Go to settings</a>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default App
