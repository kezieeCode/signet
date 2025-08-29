import React from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import './FlightResults.css'

function FlightResults() {
  const navigate = useNavigate()
  const location = useLocation()
  
  // Get search parameters from URL or use defaults
  const searchParams = new URLSearchParams(location.search)
  const from = searchParams.get('from') || 'SFO'
  const to = searchParams.get('to') || 'NRT'
  const departDate = searchParams.get('depart') || '2/12'
  const returnDate = searchParams.get('return') || '3/7'
  const passengers = searchParams.get('passengers') || '1 adult'

  const handleBackToSearch = () => {
    navigate('/')
  }

  return (
    <div className="flight-results">
      {/* Header */}
      <header className="results-header">
        <div className="header-content">
          <div className="logo-section">
            <img src="/images/logo.png" alt="Tripma" className="logo" />
          </div>
          <nav className="header-nav">
            <a href="#flights">Flights</a>
            <a href="#hotels">Hotels</a>
            <a href="#packages">Packages</a>
            <a href="#signin">Sign in</a>
            <button className="signup-btn">Sign up</button>
          </nav>
          <button className="mobile-menu-btn">☰</button>
        </div>
      </header>

      {/* Search Bar */}
      <div className="search-bar">
        <div className="search-form-results">
          <div className="form-row">
            <div className="input-group">
              <span className="icon">✈️</span>
              <input type="text" value={from} readOnly />
            </div>
            <div className="input-group">
              <span className="icon">✈️</span>
              <input type="text" value={to} readOnly />
            </div>
            <div className="input-group">
              <span className="icon">📅</span>
              <input type="text" value={`${departDate} - ${returnDate}`} readOnly />
            </div>
            <div className="input-group">
              <span className="icon">👥</span>
              <input type="text" value={passengers} readOnly />
            </div>
            <button className="search-btn" onClick={handleBackToSearch}>Search</button>
          </div>
        </div>
        
        {/* Filters */}
        <div className="filters">
          <div className="filter-item">
            <span>Max price</span>
            <span className="arrow">▼</span>
          </div>
          <div className="filter-item">
            <span>Shops</span>
            <span className="arrow">▼</span>
          </div>
          <div className="filter-item">
            <span>Times</span>
            <span className="arrow">▼</span>
          </div>
          <div className="filter-item">
            <span>Airlines</span>
            <span className="arrow">▼</span>
          </div>
          <div className="filter-item">
            <span>Seat class</span>
            <span className="arrow">▼</span>
          </div>
          <div className="filter-item">
            <span>More</span>
            <span className="arrow">▼</span>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="main-content">
        <div className="content-grid">
          {/* Left Column - Flight Selection */}
          <div className="left-column">
            <h2>Choose a departing flight</h2>
            
            {/* Flight Options */}
            <div className="flight-options">
              <div className="flight-option">
                <div className="airline-info">
                  <img src="/images/flights/image.png" alt="Hawaiian Airlines" className="airline-logo" />
                  <div className="flight-details">
                    <div className="flight-times">7:00AM - 4:15PM</div>
                    <div className="flight-duration">16h 45m</div>
                    <div className="flight-stops">1 stop, 2h 45m in HNL</div>
                  </div>
                </div>
                <div className="flight-price">$624 round trip</div>
              </div>

              <div className="flight-option">
                <div className="airline-info">
                  <img src="/images/flights/image 2.png" alt="Japan Airlines" className="airline-logo" />
                  <div className="flight-details">
                    <div className="flight-times">9:30AM - 6:45PM</div>
                    <div className="flight-duration">17h 15m</div>
                    <div className="flight-stops">Nonstop</div>
                  </div>
                </div>
                <div className="flight-price">$789 round trip</div>
              </div>

              <div className="flight-option">
                <div className="airline-info">
                  <img src="/images/flights/image 3.png" alt="Delta Airlines" className="airline-logo" />
                  <div className="flight-details">
                    <div className="flight-times">11:15AM - 8:30PM</div>
                    <div className="flight-duration">17h 15m</div>
                    <div className="flight-stops">1 stop, 1h 30m in LAX</div>
                  </div>
                </div>
                <div className="flight-price">$698 round trip</div>
              </div>

              <div className="flight-option">
                <div className="airline-info">
                  <img src="/images/flights/image 4.png" alt="United Airlines" className="airline-logo" />
                  <div className="flight-details">
                    <div className="flight-times">2:45PM - 12:00AM</div>
                    <div className="flight-duration">18h 15m</div>
                    <div className="flight-stops">1 stop, 3h 15m in SFO</div>
                  </div>
                </div>
                <div className="flight-price">$745 round trip</div>
              </div>

              <div className="flight-option">
                <div className="airline-info">
                  <img src="/images/flights/image 5.png" alt="American Airlines" className="airline-logo" />
                  <div className="flight-details">
                    <div className="flight-times">6:00PM - 3:15AM</div>
                    <div className="flight-duration">16h 15m</div>
                    <div className="flight-stops">Nonstop</div>
                  </div>
                </div>
                <div className="flight-price">$892 round trip</div>
              </div>

              <div className="flight-option">
                <div className="airline-info">
                  <img src="/images/flights/image 6.png" alt="Korean Air" className="airline-logo" />
                  <div className="flight-details">
                    <div className="flight-times">8:30PM - 5:45AM</div>
                    <div className="flight-duration">17h 15m</div>
                    <div className="flight-stops">1 stop, 2h 15m in ICN</div>
                  </div>
                </div>
                <div className="flight-price">$756 round trip</div>
              </div>
            </div>

            <button className="show-all-flights">Show all flights</button>

            {/* Flight Map */}
            <div className="flight-map">
              <img src="/images/flights/flight-map.png" alt="Flight path from NRT to SFO" className="map-image" />
            </div>
          </div>

          {/* Right Column - Price Information */}
          <div className="right-column">
            {/* Price Grid */}
            <div className="price-grid-section">
              <h3>Price grid (flexible dates)</h3>
              <div className="price-grid">
                <div className="price-grid-scroll">
                  <table>
                    <thead>
                      <tr>
                        <th></th>
                        <th>2/12</th>
                        <th>2/13</th>
                        <th>2/14</th>
                        <th>2/15</th>
                        <th>2/16</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>3/7</td>
                        <td className="price">$592</td>
                        <td className="price">$624</td>
                        <td className="price">$698</td>
                        <td className="price">$745</td>
                        <td className="price">$789</td>
                      </tr>
                      <tr>
                        <td>3/8</td>
                        <td className="price">$598</td>
                        <td className="price">$630</td>
                        <td className="price">$704</td>
                        <td className="price">$751</td>
                        <td className="price">$795</td>
                      </tr>
                      <tr>
                        <td>3/9</td>
                        <td className="price">$605</td>
                        <td className="price">$637</td>
                        <td className="price">$711</td>
                        <td className="price">$758</td>
                        <td className="price">$802</td>
                      </tr>
                      <tr>
                        <td>3/10</td>
                        <td className="price">$612</td>
                        <td className="price">$644</td>
                        <td className="price">$718</td>
                        <td className="price">$765</td>
                        <td className="price">$809</td>
                      </tr>
                      <tr>
                        <td>3/11</td>
                        <td className="price">$1,208</td>
                        <td className="price">$1,245</td>
                        <td className="price">$1,298</td>
                        <td className="price">$1,308</td>
                        <td className="price">$1,308</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            {/* Price History */}
            <div className="price-history-section">
              <h3>Price history</h3>
              <div className="price-chart">
                <div className="chart-container">
                  <div className="chart-line"></div>
                  <div className="chart-points">
                    <div className="point" style={{ left: '10%', top: '60%' }}></div>
                    <div className="point" style={{ left: '25%', top: '45%' }}></div>
                    <div className="point" style={{ left: '40%', top: '70%' }}></div>
                    <div className="point" style={{ left: '55%', top: '35%' }}></div>
                    <div className="point" style={{ left: '70%', top: '50%' }}></div>
                    <div className="point" style={{ left: '85%', top: '30%' }}></div>
                  </div>
                  <div className="chart-axis">
                    <span className="y-axis">$1000</span>
                    <span className="y-axis">$750</span>
                    <span className="y-axis">$500</span>
                    <span className="y-axis">$250</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Price Rating */}
            <div className="price-rating-section">
              <h3>Price rating</h3>
              <button className="buy-soon-btn">Buy soon</button>
              <p className="price-analysis">
                Average cost is $750, but could rise 18% to $885 in two weeks.
                Tripma analyzes data for the best deal.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Travel Recommendations */}
      <section className="travel-recommendations">
        {/* Hotels in Japan */}
        <div className="recommendation-section">
          <div className="section-header">
            <h2>Find places to stay in Japan</h2>
            <a href="#all-hotels" className="all-link">All →</a>
          </div>
          <div className="recommendation-grid">
            <div className="recommendation-card">
              <img src="/images/flights/image.png" alt="Hotel Kaneyamaen and Bessho SASA" className="card-image" />
              <div className="card-content">
                <h3>Hotel Kaneyamaen and Bessho SASA</h3>
                <p>At the base of Mount Fuji, a traditional ryokan with a modern twist. Private onsen and multi-course dinner.</p>
              </div>
            </div>
            <div className="recommendation-card">
              <img src="/images/flights/image 2.png" alt="HOTEL THE FLAG 大阪市" className="card-image" />
              <div className="card-content">
                <h3>HOTEL THE FLAG 大阪市</h3>
                <p>In Osaka, near Dotonbori and Shinsaibashi shopping street.</p>
              </div>
            </div>
            <div className="recommendation-card">
              <img src="/images/flights/image 3.png" alt="9 Hours Shinjuku" className="card-image" />
              <div className="card-content">
                <h3>9 Hours Shinjuku</h3>
                <p>Unique Japanese capsule hotel near Shinjuku train stations, accessible from Narita airport via NEX train.</p>
              </div>
            </div>
          </div>
        </div>

        {/* Popular Destinations */}
        <div className="recommendation-section">
          <div className="section-header">
            <h2>People in San Francisco also searched for</h2>
            <a href="#all-destinations" className="all-link">All →</a>
          </div>
          <div className="recommendation-grid">
            <div className="recommendation-card">
              <img src="/images/flights/image 4.png" alt="Shanghai, China" className="card-image" />
              <div className="card-content">
                <h3>Shanghai, China</h3>
                <p>An international city rich in culture.</p>
                <div className="card-price">$598</div>
              </div>
            </div>
            <div className="recommendation-card">
              <img src="/images/flights/image 5.png" alt="Nairobi, Kenya" className="card-image" />
              <div className="card-content">
                <h3>Nairobi, Kenya</h3>
                <p>Dubbed the Safari Capital of the World.</p>
                <div className="card-price">$1,248</div>
              </div>
            </div>
            <div className="recommendation-card">
              <img src="/images/flights/image 6.png" alt="Seoul, South Korea" className="card-image" />
              <div className="card-content">
                <h3>Seoul, South Korea</h3>
                <p>This modern city is a traveler's dream.</p>
                <div className="card-price">$589</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="footer-content">
          <div className="footer-section">
            <div className="footer-logo">
              <img src="/images/logo.png" alt="Tripma logo" className="footer-logo-img" />
            </div>
          </div>
          <div className="footer-section">
            <h4>About</h4>
            <ul>
              <li><a href="#about">About Tripma</a></li>
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
            <p>Tripma for Android</p>
            <p>Tripma for iOS</p>
            <p>Mobile site</p>
            <div className="app-badges">
              <div className="app-badge">Download on the App Store</div>
              <div className="app-badge">GET IT ON Google Play</div>
            </div>
          </div>
        </div>
        <div className="footer-bottom">
          <div className="social-links">
            <a href="#twitter">🐦</a>
            <a href="#instagram">📷</a>
            <a href="#facebook">📘</a>
          </div>
          <div className="copyright">© 2020 Tripma incorporated</div>
        </div>
      </footer>
    </div>
  )
}

export default FlightResults
