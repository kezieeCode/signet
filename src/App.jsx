import './App.css'
import { useRef } from 'react'
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
import speakImage from './assets/images/pictures/speak.png'
import thinkImage from './assets/images/pictures/think.png'
import testimonialsImage from './assets/images/pictures/testimonials.png'
import invertedCurve from './assets/images/vectors/inverted_curve.png'
import liquidImage from './assets/images/vectors/liquid.png'
import liquid1Image from './assets/images/vectors/liquid1.png'
import liquid2Image from './assets/images/vectors/liquid2.png'
import waveImage from './assets/images/vectors/wave.png'
import spiralImage from './assets/images/vectors/spiral.png'
import belowImage from './assets/images/vectors/below.png'

function App() {
  const row1Ref = useRef(null)
  const row2Ref = useRef(null)

  const scrollRow = (rowRef, direction) => {
    if (rowRef.current) {
      const scrollAmount = 300
      rowRef.current.scrollBy({
        left: direction === 'left' ? -scrollAmount : scrollAmount,
        behavior: 'smooth'
      })
    }
  }

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
              <div className="feature-box studio-card">
                <div className="feature-content">
                  <h3 className="feature-title">Studio:</h3>
                  <p className="feature-text">Full-stack marketing powered by SigNet</p>
                </div>
                <div className="feature-icon">
                  <img src={studioIcon} alt="Studio" />
                </div>
              </div>
              
              <div className="feature-box network-card">
                <div className="feature-content">
                  <h3 className="feature-title">Network:</h3>
                  <p className="feature-text">Private network powered by the insight of our experts</p>
                </div>
                <div className="feature-icon">
                  <img src={networkIcon} alt="Network" />
                </div>
              </div>
              
              <div className="feature-box fellowship-card">
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
            <img src={speakImage} alt="Speak" className="crib-image-img" />
          </div>
        </div>
      </section>

      {/* GTM Studio Section */}
      <section className="gtm-studio-section">
        <div className="gtm-studio-container">
          <div className="gtm-studio-image">
            <img src={thinkImage} alt="Cross-Market Campaign" className="gtm-studio-img" />
          </div>
          <div className="gtm-studio-content">
            <div className="gtm-studio-tag">GTM Studio</div>
            <h2 className="gtm-studio-heading">Cross-Market Campaign</h2>
            <p className="gtm-studio-description">
              SigNet is a global marketing network that handpicks top-tier talent and aligns incentives through a contributor-driven DAO. Together, we help companies scale, grow, and accelerate with precision.
            </p>
          </div>
        </div>
      </section>

      {/* Success Stories Section */}
      <section className="success-stories-section">
        <div className="success-stories-container">
          <div className="success-stories-header">
            <div className="success-stories-tag">Case study</div>
            <h2 className="success-stories-heading">Success Stories From Our Network</h2>
          </div>
          <div className="success-stories-rows">
            {/* Row 1 */}
            <div className="success-stories-row-wrapper">
              <button 
                className="scroll-arrow scroll-arrow-left" 
                onClick={() => scrollRow(row1Ref, 'left')}
                aria-label="Scroll left"
              ></button>
              <div className="success-stories-row" ref={row1Ref}>
                <div className="project-card">
                  <img src={testimonialsImage} alt="Viral.fun" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">Viral.fun</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
                <div className="project-card">
                  <img src={testimonialsImage} alt="Convogram" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">Convogram</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
                <div className="project-card">
                  <img src={testimonialsImage} alt="NextBerries" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">NextBerries</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
                <div className="project-card">
                  <img src={testimonialsImage} alt="AstraLab" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">AstraLab</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
                <div className="project-card">
                  <img src={testimonialsImage} alt="Seriphics" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">Seriphics</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
              </div>
              <button 
                className="scroll-arrow scroll-arrow-right" 
                onClick={() => scrollRow(row1Ref, 'right')}
                aria-label="Scroll right"
              ></button>
            </div>

            {/* Row 2 */}
            <div className="success-stories-row-wrapper">
              <button 
                className="scroll-arrow scroll-arrow-left" 
                onClick={() => scrollRow(row2Ref, 'left')}
                aria-label="Scroll left"
              ></button>
              <div className="success-stories-row" ref={row2Ref}>
                <div className="project-card">
                  <img src={testimonialsImage} alt="HUMB Exchange" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">HUMB Exchange</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
                <div className="project-card">
                  <img src={testimonialsImage} alt="SP3NDdotshop" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">SP3NDdotshop</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
                <div className="project-card">
                  <img src={testimonialsImage} alt="Tenex" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">Tenex</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
                <div className="project-card">
                  <img src={testimonialsImage} alt="Cor" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">Cor</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
                <div className="project-card">
                  <img src={testimonialsImage} alt="Next" className="project-card-image" />
                  <div className="project-card-content">
                    <h3 className="project-card-name">Next</h3>
                    <button className="project-card-button">View project</button>
                  </div>
                </div>
              </div>
              <button 
                className="scroll-arrow scroll-arrow-right" 
                onClick={() => scrollRow(row2Ref, 'right')}
                aria-label="Scroll right"
              ></button>
            </div>
          </div>
        </div>
      </section>

      {/* Statistics Section */}
      <section className="statistics-section">
        <div className="statistics-background">
          <img src={invertedCurve} alt="Decorative curve" className="statistics-curve" />
        </div>
        <div className="statistics-container">
          <div className="statistics-header">
            <div className="statistics-left">
              <div className="statistics-tag">
                <span className="statistics-tag-dot"></span>
                <span>STATISTICS</span>
              </div>
              <h2 className="statistics-heading">Our Impact in Numbers</h2>
            </div>
            <div className="statistics-right">
              <p className="statistics-description">
                Unlike any other agencies, we're a highly vetted, contributor-owned network of top marketers, creatives, developers, AI enthusiasts, and strategists, working side by side with clients to build the future of crypto marketing.
              </p>
            </div>
          </div>
          <div className="statistics-cards">
            <div className="stat-card">
              <div className="stat-number">100+</div>
              <div className="stat-label">Members</div>
            </div>
            <div className="stat-card">
              <div className="stat-number">6</div>
              <div className="stat-label">continent</div>
            </div>
            <div className="stat-card">
              <div className="stat-number">1</div>
              <div className="stat-label">Mission</div>
            </div>
          </div>
        </div>
      </section>

      {/* Fellowship Blog Section */}
      <section className="fellowship-blog-section">
        <div className="fellowship-blog-container">
          <div className="fellowship-blog-main">
            <div className="fellowship-blog-content">
              <div className="fellowship-blog-tag">
                <span className="fellowship-blog-tag-dot"></span>
                <span>fellowship / Blog</span>
              </div>
              <h2 className="fellowship-blog-heading">Where Tomorrow's Web3 Leaders Begin</h2>
              <div className="fellowship-blog-text">
                <p className="fellowship-blog-paragraph">
                  The Crib Fellowship is a comprehensive program designed to onboard and upskill the next generation of Web3 marketing experts. Through hands-on training, mentorship, and real-world project experience, we're building a pipeline of talented contributors who will shape the future of crypto marketing.
                </p>
                <p className="fellowship-blog-paragraph">
                  Our blog and newsletter provide insights, strategies, and updates from the front lines of Web3 marketing. Stay ahead of the curve with expert analysis, case studies, and industry trends. Public access coming in 2026.
                </p>
              </div>
              <div className="fellowship-blog-buttons">
                <button className="fellowship-blog-button-view">• View All Blog</button>
                <button className="fellowship-blog-button-call">Book a call</button>
              </div>
              <div className="fellowship-blog-cards">
                <div className="fellowship-blog-card">
                  <div className="fellowship-blog-card-image-wrapper">
                    <img src={liquid1Image} alt="How to Build a Calming Night Routine" className="fellowship-blog-card-image" />
                    <div className="fellowship-blog-card-icon">→</div>
                  </div>
                  <h3 className="fellowship-blog-card-title">How to Build a Calming Night Routine</h3>
                </div>
                <div className="fellowship-blog-card">
                  <div className="fellowship-blog-card-image-wrapper">
                    <img src={liquid2Image} alt="Why Digital Detox Improves Mental Clarity" className="fellowship-blog-card-image" />
                    <div className="fellowship-blog-card-icon">→</div>
                  </div>
                  <h3 className="fellowship-blog-card-title">Why Digital Detox Improves Mental Clarity</h3>
                </div>
              </div>
            </div>
            <div className="fellowship-blog-feature">
              <img src={liquidImage} alt="The Science Behind Deep Sleep" className="fellowship-blog-feature-image" />
              <h3 className="fellowship-blog-feature-title">The Science Behind Deep Sleep</h3>
            </div>
          </div>
        </div>
      </section>

      {/* Book a Call Section */}
      <section className="book-call-section">
        <div className="book-call-container">
          <div className="book-call-background">
            <img src={waveImage} alt="Wave decoration" className="book-call-wave" />
            <img src={spiralImage} alt="Spiral decoration" className="book-call-spiral" />
          </div>
          <div className="book-call-content">
            <h2 className="book-call-heading">
              <span className="book-call-heading-line1">Book a 15-minute Intro</span>
              <span className="book-call-heading-line2">Call</span>
            </h2>
            <p className="book-call-subtitle">Ready to work with us? Let's talk.</p>
            <button className="book-call-button">Secure a Time.</button>
          </div>
        </div>
      </section>

      {/* Footer Section */}
      <footer className="footer-section">
        <div className="footer-background">
          <img src={belowImage} alt="Decorative curve" className="footer-curve" />
        </div>
        <div className="footer-container">
          <div className="footer-logo">
            <img src={logoImage} alt="Signet Logo" className="footer-logo-image" />
          </div>
          <div className="footer-nav">
            <div className="footer-nav-column">
              <h4 className="footer-nav-title">Main page</h4>
              <ul className="footer-nav-links">
                <li><a href="#" className="footer-nav-link">• Home</a></li>
                <li><a href="#" className="footer-nav-link">GMT Studios</a></li>
                <li><a href="#" className="footer-nav-link">Fellowship</a></li>
                <li><a href="#" className="footer-nav-link">Learns</a></li>
              </ul>
            </div>
            <div className="footer-nav-column">
              <h4 className="footer-nav-title">Action</h4>
              <ul className="footer-nav-links">
                <li><a href="#" className="footer-nav-link">Book A Call</a></li>
                <li><a href="#" className="footer-nav-link">Become A Member</a></li>
              </ul>
            </div>
          </div>
          <div className="footer-social">
            <a href="#" className="footer-social-icon footer-social-instagram" aria-label="Instagram">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <rect x="2" y="2" width="20" height="20" rx="10" fill="black" stroke="#7FFF00" strokeWidth="2"/>
                <rect x="7" y="7" width="10" height="10" rx="2" stroke="#7FFF00" strokeWidth="1.5" fill="none"/>
                <circle cx="15" cy="9" r="1" fill="#7FFF00"/>
              </svg>
            </a>
            <a href="#" className="footer-social-icon" aria-label="X (Twitter)">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <circle cx="12" cy="12" r="10" fill="#666666"/>
                <path d="M8 8L16 16M16 8L8 16" stroke="white" strokeWidth="2" strokeLinecap="round"/>
              </svg>
            </a>
            <a href="#" className="footer-social-icon" aria-label="LinkedIn">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <circle cx="12" cy="12" r="10" fill="#666666"/>
                <path d="M9 9V19M9 9C9 8 9.5 7 11 7C12.5 7 13 8 13 9V19M9 9H7M13 9H15M7 19H9M13 19H15M7 12H9M13 12H15" stroke="white" strokeWidth="1.5" strokeLinecap="round"/>
              </svg>
            </a>
            <a href="#" className="footer-social-icon" aria-label="Facebook">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <circle cx="12" cy="12" r="10" fill="#666666"/>
                <path d="M11 7H13V9H11V7ZM11 9V11H13V9H11ZM11 11V18H9V11H7V9H9V8C9 7.4 9.4 7 10 7H13V9H11V11Z" fill="white"/>
              </svg>
            </a>
          </div>
        </div>
      </footer>
    </div>
  )
}

export default App
