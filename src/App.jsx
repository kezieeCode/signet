import './App.css'
import logoImage from './assets/images/logo .png'
import astra from './assets/images/sponsors/astra.png'
import convogram from './assets/images/sponsors/convogram.png'
import cor from './assets/images/sponsors/cor.png'
import humb from './assets/images/sponsors/Humb.png'
import next from './assets/images/sponsors/Next.png'
import seriphics from './assets/images/sponsors/seriphics.png'
import spend from './assets/images/sponsors/spend.png'
import tenex from './assets/images/sponsors/Tenex.png'
import viral from './assets/images/sponsors/viral.png'
import curvedImage from './assets/images/vectors/curved.png'
import studioIcon from './assets/images/icons/studio.png'
import networkIcon from './assets/images/icons/network.png'
import fellowshipIcon from './assets/images/icons/fellowship.png'

function App() {
  const partners = [
    { name: 'Tenex', image: tenex },
    { name: 'Spend', image: spend },
    { name: 'Viral', image: viral },
    { name: 'Next', image: next },
    { name: 'Humb', image: humb },
    { name: 'Astra', image: astra },
    { name: 'Seriphics', image: seriphics },
    { name: 'Convogram', image: convogram },
    { name: 'Cor', image: cor }
  ]

  return (
    <div className="app">
      {/* Header */}
      <header className="header">
        <div className="header-container">
          <div className="logo-section">
            <img src={logoImage} alt="Signet Logo" className="logo-icon" />
          </div>

          <div className="header-actions">
            <nav className="nav-links">
              <a href="#" className="nav-link active">Home</a>
              <a href="#" className="nav-link">GTM Studios</a>
              <a href="#" className="nav-link">Fellowship</a>
              <a href="#" className="nav-link">learns</a>
            </nav>
            <button className="btn-member">Become A Member</button>
            <button className="btn-call">Book A Call</button>
          </div>
      </div>
      </header>

      {/* Hero Section */}
      <main className="hero">
        <div className="hero-content">
          <h1 className="hero-headline">
            <span className="hero-main">Building the Future of</span>{' '}
            <span className="hero-accent">Crypto Marketing</span>
          </h1>
          <p className="hero-description">
            A contributor-driven network of world-class experts delivering proven growth systems, cross-market GTM execution, and long-term adoption for web3 brands.
          </p>
          <button className="btn-learn-more">Learn more</button>
        </div>
      </main>

      {/* Partners Section */}
      <section className="partners-section">
        <div className="partners-scroll">
          <div className="partners-track">
            {partners.map((partner, index) => (
              <div key={index} className="partner-logo">
                <img src={partner.image} alt={partner.name} />
              </div>
            ))}
            {partners.map((partner, index) => (
              <div key={`duplicate-${index}`} className="partner-logo">
                <img src={partner.image} alt={partner.name} />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* What We Have To Offer Section */}
      <section className="offer-section">
        <div className="offer-container">
          <div className="offer-content">
            <div className="offer-tag">
              <span className="tag-dot"></span>
              <span>WHAT WE HAVE TO OFFER</span>
            </div>
            <h2 className="offer-heading">Global Expertise for High-Impact Crypto Marketing</h2>
            <p className="offer-description">
              From NYC to Texas, Australia, Lagos & beyond. SigNet matches world-class marketers with crypto brands to drive strategic, measurable and data-led growth.
            </p>
            
            <div className="features-grid">
              <div className="feature-box">
                <div className="feature-content">
                  <h3 className="feature-title">Studio:</h3>
                  <p className="feature-text">Full-stack marketing powered by SigNet</p>
                </div>
                <div className="feature-icon">
                  <img src={studioIcon} alt="Studio" />
                </div>
              </div>
              
              <div className="feature-box">
                <div className="feature-content">
                  <h3 className="feature-title">Network:</h3>
                  <p className="feature-text">Private network powered by the insight of our experts</p>
                </div>
                <div className="feature-icon">
                  <img src={networkIcon} alt="Network" />
                </div>
              </div>
              
              <div className="feature-box">
                <div className="feature-content">
                  <h3 className="feature-title">Fellowship</h3>
                  <p className="feature-text">Onboarding & upskilling the next generation of experts</p>
                </div>
                <div className="feature-icon">
                  <img src={fellowshipIcon} alt="Fellowship" />
                </div>
              </div>
            </div>
          </div>
          
          <div className="offer-graphic">
            <img src={curvedImage} alt="Curved graphic" />
          </div>
        </div>
      </section>

      {/* Crib Network Section */}
      <section className="crib-section">
        <div className="crib-container">
          <div className="crib-content">
            <div className="crib-tag">Crib Network</div>
            <h2 className="crib-heading">Marketing. Community. Development.</h2>
            <p className="crib-description">
              The three pillars that underpin the Crib Network's evolving ecosystem. Together, they foster creativity, nurture community growth, and unlock strategic potential across the entire network.
            </p>
          </div>
          <div className="crib-image">
            <div className="crib-image-placeholder">
              {/* Placeholder for the image - user can add the actual image later */}
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

export default App
