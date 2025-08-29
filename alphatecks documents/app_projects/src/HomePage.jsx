import { useState } from 'react'
import { useNavigate } from 'react-router-dom'

function HomePage() {
  const [fromLocation, setFromLocation] = useState('San Francisco (SFO)')
  const [toLocation, setToLocation] = useState('Tokyo (NRT)')
  const [departDate, setDepartDate] = useState('2/12')
  const [returnDate, setReturnDate] = useState('3/7')
  const [adults, setAdults] = useState(1)
  const navigate = useNavigate()

  const handleSearch = () => {
    const searchParams = new URLSearchParams({
      from: fromLocation || 'SFO',
      to: toLocation || 'NRT',
      depart: departDate || '2/12',
      return: returnDate || '3/7',
      passengers: `${adults} adult${adults > 1 ? 's' : ''}`
    })

    const url = `/flight-results?${searchParams.toString()}`
    navigate(url)
  }

  return (
    <div className="App">
      <header className="header">
        <div className="header-content">
          <div className="logo-section">
            <img src="/images/logo.png" alt="Tripma logo" />
          </div>
          <nav className="header-nav">
            <a href="#flights">Flights</a>
            <a href="#hotels">Hotels</a>
            <a href="#packages">Packages</a>
            <a href="#signin">Sign in</a>
            <button className="signup-btn">Sign up</button>
          </nav>
        </div>
      </header>

      <main className="main-content">
        <div className="hero-section">
          <h1>Find your next adventure</h1>
          <p>Discover amazing destinations and book your perfect trip</p>
        </div>

        <div className="search-form">
          <div className="form-row">
            <div className="input-group">
              <span className="icon">✈️</span>
              <input
                type="text"
                placeholder="From where?"
                value={fromLocation}
                onChange={(e) => setFromLocation(e.target.value)}
              />
            </div>
            <div className="input-group">
              <span className="icon">✈️</span>
              <input
                type="text"
                placeholder="Where to?"
                value={toLocation}
                onChange={(e) => setToLocation(e.target.value)}
              />
            </div>
            <div className="input-group">
              <span className="icon">📅</span>
              <input
                type="text"
                placeholder="Depart - Return"
                value={`${departDate} - ${returnDate}`}
                readOnly
              />
            </div>
            <div className="input-group">
              <span className="icon">👥</span>
              <input
                type="text"
                placeholder="Passengers"
                value={`${adults} adult${adults > 1 ? 's' : ''}`}
                readOnly
              />
            </div>
            <button className="search-btn" onClick={handleSearch}>
              Search
            </button>
          </div>
        </div>
      </main>
    </div>
  )
}

export default HomePage
