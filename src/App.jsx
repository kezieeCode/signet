import './App.css'
import { useRef, useState } from 'react'
import logoImage from './assets/images/logo .png'
import logoBlackImage from './assets/images/logo-black.png'
import collaborateImage from './assets/images/pictures/collaborate.png'
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
import crackImage from './assets/images/vectors/crack.png'

function App() {
  const [currentPage, setCurrentPage] = useState('home')
  const [activeTestimonial, setActiveTestimonial] = useState(0)
  const row1Ref = useRef(null)
  const row2Ref = useRef(null)
  const [waitlistName, setWaitlistName] = useState('')
  const [waitlistEmail, setWaitlistEmail] = useState('')

  const scrollRow = (rowRef, direction) => {
    if (rowRef.current) {
      const cardWidth = 320 + 24 // card width + gap
      const scrollAmount = cardWidth
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
    <div className={`app ${currentPage === 'gtm-studios' ? 'gtm-studios-theme' : ''} ${currentPage === 'learns' ? 'learns-theme' : ''}`}>
      {/* Header */}
      <header className={`header ${currentPage === 'gtm-studios' || currentPage === 'learns' ? 'header-light' : ''}`}>
        <div className="header-container">
          <div className="logo-section">
            <img 
              src={currentPage === 'gtm-studios' || currentPage === 'learns' ? logoBlackImage : logoImage} 
              alt="Signet Logo" 
              className="logo-icon" 
            />
          </div>

          <div className="header-actions">
            <nav className="nav-links">
              <a 
                href="#" 
                className={`nav-link ${currentPage === 'home' ? 'active' : ''}`}
                onClick={(e) => { e.preventDefault(); setCurrentPage('home'); }}
              >
                Home
              </a>
              <a 
                href="#" 
                className={`nav-link ${currentPage === 'gtm-studios' ? 'active' : ''}`}
                onClick={(e) => { e.preventDefault(); setCurrentPage('gtm-studios'); }}
              >
                GTM Studios
              </a>
              <a 
                href="#" 
                className={`nav-link ${currentPage === 'fellowship' ? 'active' : ''}`}
                onClick={(e) => { e.preventDefault(); setCurrentPage('fellowship'); }}
              >
                Fellowship
              </a>
              <a 
                href="#" 
                className={`nav-link ${currentPage === 'learns' ? 'active' : ''}`}
                onClick={(e) => { e.preventDefault(); setCurrentPage('learns'); }}
              >
                learns
              </a>
            </nav>
            <button className="btn-member">Become A Member</button>
            <button className="btn-call">Book A Call</button>
          </div>
      </div>
      </header>

      {currentPage === 'home' && (
        <>
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
        </div>
        <div className="offer-graphic">
          <img src={curvedImage} alt="Curved graphic" />
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
        </>
      )}

      {currentPage === 'gtm-studios' && (
        <div className="gtm-studios-page">
          {/* About Section */}
          <section className="gtm-studios-hero">
            <div className="gtm-studios-container">
              <div className="gtm-studios-tag">
                <span>About</span>
              </div>
              <h1 className="gtm-studios-heading">We build with vision</h1>
              <div className="gtm-studios-description">
                <p>
                  Marketing needs more than a template. SigNet was built to fix that gap. We link forward-thinking crypto brands with a rigorously vetted network of elite marketers to supercharge their go-to-market efforts.
                </p>
                <p>
                  From launch to market dominance, our multifaceted team of product managers, growth marketers, advisers, creatives, brand strategists, and social media leads delivers measurable results for Web3 products.
                </p>
              </div>
            </div>
          </section>

          {/* Statistics Section */}
          <section className="gtm-studios-stats">
            <div className="gtm-studios-stats-container">
              <div className="gtm-studios-stat-card">
                <div className="gtm-studios-stat-number">100+</div>
                <div className="gtm-studios-stat-label">Members</div>
              </div>
              <div className="gtm-studios-stat-card">
                <div className="gtm-studios-stat-number">6</div>
                <div className="gtm-studios-stat-label">Continent</div>
              </div>
              <div className="gtm-studios-stat-card">
                <div className="gtm-studios-stat-number">1</div>
                <div className="gtm-studios-stat-label">Mission</div>
              </div>
            </div>
          </section>

          {/* Collaborate Image Section */}
          <section className="gtm-studios-image-section">
            <div className="gtm-studios-image-container">
              <div className="gtm-studios-image-background">
                <img src={crackImage} alt="" className="gtm-studios-crack-bg" />
              </div>
              <img src={collaborateImage} alt="Team Collaboration" className="gtm-studios-collaborate-image" />
            </div>
          </section>

          {/* Services Section */}
          <section className="gtm-studios-services">
            <div className="gtm-studios-services-container">
              <div className="gtm-studios-services-tag">
                <span className="gtm-studios-services-dot"></span>
                <span>Services</span>
              </div>
              <h2 className="gtm-studios-services-heading">What we offer</h2>
              <p className="gtm-studios-services-description">
                Built as a decentralised talent pool, Signet connects projects with niche experts and seasoned operators. From token-era launches to infrastructure, DeFi growth and B2B infra content marketing & more. We know exactly what you need.
              </p>
              <div className="gtm-studios-services-grid">
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M12 2L2 7L12 12L22 7L12 2Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M2 17L12 22L22 17" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M2 12L12 17L22 12" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <circle cx="12" cy="12" r="2" fill="#7FFF00"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Product management</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M5 12L12 5L19 12" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M12 19V5" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M5 12L12 19L19 12" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Growth Hacking</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <rect x="2" y="6" width="20" height="12" rx="2" stroke="#7FFF00" strokeWidth="2"/>
                      <path d="M8 6V4C8 2.89543 8.89543 2 10 2H14C15.1046 2 16 2.89543 16 4V6" stroke="#7FFF00" strokeWidth="2"/>
                      <circle cx="12" cy="12" r="2" fill="#7FFF00"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Video Marketing</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M14 2H6C5.46957 2 4.96086 2.21071 4.58579 2.58579C4.21071 2.96086 4 3.46957 4 4V20C4 20.5304 4.21071 21.0391 4.58579 21.4142C4.96086 21.7893 5.46957 22 6 22H18C18.5304 22 19.0391 21.7893 19.4142 21.4142C19.7893 21.0391 20 20.5304 20 20V8L14 2Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M14 2V8H20" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M16 13H8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M16 17H8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M10 9H8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Technical Contents</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <circle cx="12" cy="12" r="4" stroke="#7FFF00" strokeWidth="2"/>
                      <path d="M12 2V6M12 18V22M22 12H18M6 12H2" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Visuals</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M6.5 2H20V22H6.5A2.5 2.5 0 0 1 4 19.5V4.5A2.5 2.5 0 0 1 6.5 2Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M8 7H16" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M8 11H16" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Storytelling</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M12 2L2 7L12 12L22 7L12 2Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M2 17L12 22L22 17" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M2 12L12 17L22 12" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Brand strategy</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <circle cx="12" cy="12" r="10" stroke="#7FFF00" strokeWidth="2"/>
                      <path d="M12 2C15.31 2 18.23 3.89 19.62 6.68" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M12 22C8.69 22 5.77 20.11 4.38 17.32" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M12 2V6M12 18V22M22 12H18M6 12H2" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Social media</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <circle cx="11" cy="11" r="8" stroke="#7FFF00" strokeWidth="2"/>
                      <path d="M21 21L16.65 16.65" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Research</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <rect x="2" y="3" width="20" height="14" rx="2" stroke="#7FFF00" strokeWidth="2"/>
                      <path d="M8 21H16" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M12 17V21" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">PR & Press</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2Z" stroke="#7FFF00" strokeWidth="2"/>
                      <path d="M12 6V12L16 14" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M12 2L12 6M22 12L18 12M12 18L12 22M2 12L6 12" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Analytics</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M17 21V19C17 17.9391 16.5786 16.9217 15.8284 16.1716C15.0783 15.4214 14.0609 15 13 15H5C3.93913 15 2.92172 15.4214 2.17157 16.1716C1.42143 16.9217 1 17.9391 1 19V21" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <circle cx="9" cy="7" r="4" stroke="#7FFF00" strokeWidth="2"/>
                      <path d="M23 21V19C22.9993 18.1137 22.7044 17.2528 22.1614 16.5523C21.6184 15.8519 20.8581 15.3516 20 15.13" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M16 3.13C16.8604 3.35031 17.623 3.85071 18.1676 4.55232C18.7122 5.25392 19.0078 6.11683 19.0078 7.005C19.0078 7.89318 18.7122 8.75608 18.1676 9.45769C17.623 10.1593 16.8604 10.6597 16 10.88" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Community Management</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M14 2H6C5.46957 2 4.96086 2.21071 4.58579 2.58579C4.21071 2.96086 4 3.46957 4 4V20C4 20.5304 4.21071 21.0391 4.58579 21.4142C4.96086 21.7893 5.46957 22 6 22H18C18.5304 22 19.0391 21.7893 19.4142 21.4142C19.7893 21.0391 20 20.5304 20 20V8L14 2Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M14 2V8H20" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M16 13H8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M16 17H8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M10 9H8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Whitepaper</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M9 7L6 4L3 7" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M6 4V14" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M15 17L18 20L21 17" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M18 20V10" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M8 14L12 10L16 14" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Developer Relations</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M10 20L14 4" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M2 8L10 12L2 16L10 20L18 16L10 12L18 8L10 4L2 8Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M18 8L22 10L18 12" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M18 12L22 14L18 16" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Full-stack Development</span>
                </div>
                <div className="gtm-studios-service-card">
                  <div className="gtm-studios-service-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M17 21V19C17 17.9391 16.5786 16.9217 15.8284 16.1716C15.0783 15.4214 14.0609 15 13 15H5C3.93913 15 2.92172 15.4214 2.17157 16.1716C1.42143 16.9217 1 17.9391 1 19V21" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <circle cx="9" cy="7" r="4" stroke="#7FFF00" strokeWidth="2"/>
                      <path d="M23 21V19C22.9993 18.1137 22.7044 17.2528 22.1614 16.5523C21.6184 15.8519 20.8581 15.3516 20 15.13" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M16 3.13C16.8604 3.35031 17.623 3.85071 18.1676 4.55232C18.7122 5.25392 19.0078 6.11683 19.0078 7.005C19.0078 7.89318 18.7122 8.75608 18.1676 9.45769C17.623 10.1593 16.8604 10.6597 16 10.88" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                  <span className="gtm-studios-service-name">Partnerships</span>
                </div>
              </div>
            </div>
          </section>

          {/* Our Community Section */}
          <section className="gtm-studios-community">
            <div className="gtm-studios-community-container">
              <div className="gtm-studios-community-tag">
                <span className="gtm-studios-community-dot"></span>
                <span>Our Community</span>
              </div>
              <h2 className="gtm-studios-community-heading">
                Meet our Esteemed <span className="gtm-studios-community-highlight">Community</span> member
              </h2>
              <p className="gtm-studios-community-description">
                Within Crib Network's diverse community of web3 builders, creators, and innovators who love to co-create, test, and collaborate to grow crypto projects/companies in this space.
              </p>
              <div className="gtm-studios-community-grid">
                <div className="gtm-studios-community-card">
                  <div className="gtm-studios-community-avatar"></div>
                  <h3 className="gtm-studios-community-name">John doe</h3>
                  <p className="gtm-studios-community-role">Strategist</p>
                  <p className="gtm-studios-community-text">
                    Not some ordinary edits, we use trending effects to attract new users & leave an impactful first
                  </p>
                </div>
                <div className="gtm-studios-community-card">
                  <div className="gtm-studios-community-avatar"></div>
                  <h3 className="gtm-studios-community-name">John doe</h3>
                  <p className="gtm-studios-community-role">Strategist</p>
                  <p className="gtm-studios-community-text">
                    Not some ordinary edits, we use trending effects to attract new users & leave an impactful first
                  </p>
                </div>
                <div className="gtm-studios-community-card">
                  <div className="gtm-studios-community-avatar"></div>
                  <h3 className="gtm-studios-community-name">John doe</h3>
                  <p className="gtm-studios-community-role">Strategist</p>
                  <p className="gtm-studios-community-text">
                    Not some ordinary edits, we use trending effects to attract new users & leave an impactful first
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Who We Work With Section */}
          <section className="gtm-studios-clients">
            <div className="gtm-studios-clients-container">
              <div className="gtm-studios-clients-header">
                <h2 className="gtm-studios-clients-heading">Who We Work With</h2>
                <p className="gtm-studios-clients-subtitle">
                  Learn more about some of our best work with some of our recent clients, past and present
                </p>
              </div>
              <div className="gtm-studios-clients-grid">
                <div className="gtm-studios-client-card">
                  <img src={testimonialsImage} alt="Convogram" className="gtm-studios-client-image" />
                  <div className="gtm-studios-client-content">
                    <h3 className="gtm-studios-client-name">Convogram</h3>
                    <p className="gtm-studios-client-description">
                      Accelerated user onboarding by 150% via targeted growth campaigns and social automation, resulting in 3x community growth within Q1.
                    </p>
                    <button className="gtm-studios-client-button">View project</button>
                  </div>
                </div>
                <div className="gtm-studios-client-card">
                  <img src={testimonialsImage} alt="Seriphics" className="gtm-studios-client-image" />
                  <div className="gtm-studios-client-content">
                    <h3 className="gtm-studios-client-name">Seriphics</h3>
                    <p className="gtm-studios-client-description">
                      Refurbished branding and deployed SEO-optimised content, boosting organic traffic by 200% and securing top exchange listings.
                    </p>
                    <button className="gtm-studios-client-button">View project</button>
                  </div>
                </div>
                <div className="gtm-studios-client-card">
                  <img src={testimonialsImage} alt="NextBerries" className="gtm-studios-client-image" />
                  <div className="gtm-studios-client-content">
                    <h3 className="gtm-studios-client-name">NextBerries</h3>
                    <p className="gtm-studios-client-description">
                      Accelerated user onboarding by 150% via targeted growth campaigns and social automation, resulting in 3x community growth within Q1.
                    </p>
                    <button className="gtm-studios-client-button">View project</button>
                  </div>
                </div>
                <div className="gtm-studios-client-card">
                  <img src={testimonialsImage} alt="SP3NDdotshop" className="gtm-studios-client-image" />
                  <div className="gtm-studios-client-content">
                    <h3 className="gtm-studios-client-name">SP3NDdotshop</h3>
                    <p className="gtm-studios-client-description">
                      Refurbished branding and deployed SEO-optimised content, boosting organic traffic by 200% and securing top exchange listings.
                    </p>
                    <button className="gtm-studios-client-button">View project</button>
                  </div>
                </div>
                <div className="gtm-studios-client-card">
                  <img src={testimonialsImage} alt="AstraLab" className="gtm-studios-client-image" />
                  <div className="gtm-studios-client-content">
                    <h3 className="gtm-studios-client-name">AstraLab</h3>
                    <p className="gtm-studios-client-description">
                      Accelerated user onboarding by 150% via targeted growth campaigns and social automation, resulting in 3x community growth within Q1.
                    </p>
                    <button className="gtm-studios-client-button">View project</button>
                  </div>
                </div>
                <div className="gtm-studios-client-card">
                  <img src={testimonialsImage} alt="Viral.fun" className="gtm-studios-client-image" />
                  <div className="gtm-studios-client-content">
                    <h3 className="gtm-studios-client-name">Viral.fun</h3>
                    <p className="gtm-studios-client-description">
                      Refurbished branding and deployed SEO-optimised content, boosting organic traffic by 200% and securing top exchange listings.
                    </p>
                    <button className="gtm-studios-client-button">View project</button>
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* Pricing Section */}
          <section className="gtm-studios-pricing">
            <div className="gtm-studios-pricing-container">
              <div className="gtm-studios-pricing-tag">
                <span className="gtm-studios-pricing-dot"></span>
                <span>Pricing</span>
              </div>
              <h2 className="gtm-studios-pricing-heading">Standard packages to help you</h2>
              <p className="gtm-studios-pricing-description">
                We've outlined a few standard packages to help you understand typical cost ranges. Think of these as reference points; real pricing is tailored once we understand your product, timelines, and growth priorities.
              </p>
              <div className="gtm-studios-pricing-grid">
                <div className="gtm-studios-pricing-card">
                  <div className="gtm-studios-pricing-card-header">
                    <h3 className="gtm-studios-pricing-card-title">PR & Partnership</h3>
                    <div className="gtm-studios-pricing-icon">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M20.59 13.41L13.42 20.58C13.2343 20.767 13.0009 20.8762 12.7557 20.8863C12.5105 20.8964 12.2707 20.8068 12.075 20.63L3.42 12.58C3.23431 12.3943 3.12506 12.1623 3.10678 11.9183C3.0885 11.6743 3.1621 11.4323 3.315 11.23L11.32 2.23C11.4931 2.00645 11.7426 1.85382 12.0211 1.79951C12.2996 1.7452 12.5884 1.79257 12.835 1.93L20.83 5.93C21.077 6.06891 21.2665 6.29368 21.3652 6.56284C21.4638 6.832 21.465 7.12811 21.3684 7.39806C21.2717 7.668 21.0831 7.89431 20.8374 8.03504C20.5917 8.17576 20.3046 8.22184 20.03 8.17L15.56 7.25L20.59 13.41Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M7 7L7.01 7" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                        <text x="12" y="15" fill="white" font-family="Arial" font-size="10" font-weight="bold" text-anchor="middle">$</text>
                      </svg>
                    </div>
                  </div>
                  <div className="gtm-studios-pricing-service">
                    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M13.3333 4L6 11.3333L2.66667 8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <span>KOL Campaign</span>
                  </div>
                  <p className="gtm-studios-pricing-card-description">
                    High-impact influencers curated and managed to amplify your message, boost visibility, and ignite community engagement.
                  </p>
                  <div className="gtm-studios-pricing-price">
                    <span className="gtm-studios-pricing-amount">$10K</span>
                    <span className="gtm-studios-pricing-period">/month</span>
                  </div>
                  <button className="gtm-studios-pricing-button">Get Started</button>
                </div>

                <div className="gtm-studios-pricing-card">
                  <div className="gtm-studios-pricing-card-header">
                    <h3 className="gtm-studios-pricing-card-title">Content</h3>
                    <div className="gtm-studios-pricing-icon">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M20.59 13.41L13.42 20.58C13.2343 20.767 13.0009 20.8762 12.7557 20.8863C12.5105 20.8964 12.2707 20.8068 12.075 20.63L3.42 12.58C3.23431 12.3943 3.12506 12.1623 3.10678 11.9183C3.0885 11.6743 3.1621 11.4323 3.315 11.23L11.32 2.23C11.4931 2.00645 11.7426 1.85382 12.0211 1.79951C12.2996 1.7452 12.5884 1.79257 12.835 1.93L20.83 5.93C21.077 6.06891 21.2665 6.29368 21.3652 6.56284C21.4638 6.832 21.465 7.12811 21.3684 7.39806C21.2717 7.668 21.0831 7.89431 20.8374 8.03504C20.5917 8.17576 20.3046 8.22184 20.03 8.17L15.56 7.25L20.59 13.41Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M7 7L7.01 7" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                        <text x="12" y="15" fill="white" font-family="Arial" font-size="10" font-weight="bold" text-anchor="middle">$</text>
                      </svg>
                    </div>
                  </div>
                  <div className="gtm-studios-pricing-service">
                    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M13.3333 4L6 11.3333L2.66667 8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <span>Content Marketing</span>
                  </div>
                  <p className="gtm-studios-pricing-card-description">
                    Tailored crypto-native content frameworks with consistent, high-quality output to build authority and unlock BD opportunities.
                  </p>
                  <div className="gtm-studios-pricing-price">
                    <span className="gtm-studios-pricing-amount">$12K</span>
                    <span className="gtm-studios-pricing-period">/month</span>
                  </div>
                  <button className="gtm-studios-pricing-button">Get Started</button>
                </div>

                <div className="gtm-studios-pricing-card">
                  <div className="gtm-studios-pricing-card-header">
                    <h3 className="gtm-studios-pricing-card-title">Designs</h3>
                    <div className="gtm-studios-pricing-icon">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M20.59 13.41L13.42 20.58C13.2343 20.767 13.0009 20.8762 12.7557 20.8863C12.5105 20.8964 12.2707 20.8068 12.075 20.63L3.42 12.58C3.23431 12.3943 3.12506 12.1623 3.10678 11.9183C3.0885 11.6743 3.1621 11.4323 3.315 11.23L11.32 2.23C11.4931 2.00645 11.7426 1.85382 12.0211 1.79951C12.2996 1.7452 12.5884 1.79257 12.835 1.93L20.83 5.93C21.077 6.06891 21.2665 6.29368 21.3652 6.56284C21.4638 6.832 21.465 7.12811 21.3684 7.39806C21.2717 7.668 21.0831 7.89431 20.8374 8.03504C20.5917 8.17576 20.3046 8.22184 20.03 8.17L15.56 7.25L20.59 13.41Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M7 7L7.01 7" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                        <text x="12" y="15" fill="white" font-family="Arial" font-size="10" font-weight="bold" text-anchor="middle">$</text>
                      </svg>
                    </div>
                  </div>
                  <div className="gtm-studios-pricing-service">
                    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M13.3333 4L6 11.3333L2.66667 8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <span>Brand Identity Design</span>
                  </div>
                  <p className="gtm-studios-pricing-card-description">
                    Refined, consistent brand identity across all touchpoints to build trust and elevate your market positioning.
                  </p>
                  <div className="gtm-studios-pricing-price">
                    <span className="gtm-studios-pricing-amount">$12K</span>
                    <span className="gtm-studios-pricing-period">/month</span>
                  </div>
                  <button className="gtm-studios-pricing-button">Get Started</button>
                </div>

                <div className="gtm-studios-pricing-card">
                  <div className="gtm-studios-pricing-card-header">
                    <h3 className="gtm-studios-pricing-card-title">Community</h3>
                    <div className="gtm-studios-pricing-icon">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M20.59 13.41L13.42 20.58C13.2343 20.767 13.0009 20.8762 12.7557 20.8863C12.5105 20.8964 12.2707 20.8068 12.075 20.63L3.42 12.58C3.23431 12.3943 3.12506 12.1623 3.10678 11.9183C3.0885 11.6743 3.1621 11.4323 3.315 11.23L11.32 2.23C11.4931 2.00645 11.7426 1.85382 12.0211 1.79951C12.2996 1.7452 12.5884 1.79257 12.835 1.93L20.83 5.93C21.077 6.06891 21.2665 6.29368 21.3652 6.56284C21.4638 6.832 21.465 7.12811 21.3684 7.39806C21.2717 7.668 21.0831 7.89431 20.8374 8.03504C20.5917 8.17576 20.3046 8.22184 20.03 8.17L15.56 7.25L20.59 13.41Z" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M7 7L7.01 7" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round"/>
                        <text x="12" y="15" fill="white" font-family="Arial" font-size="10" font-weight="bold" text-anchor="middle">$</text>
                      </svg>
                    </div>
                  </div>
                  <div className="gtm-studios-pricing-service">
                    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M13.3333 4L6 11.3333L2.66667 8" stroke="#7FFF00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <span>Social Media Management:</span>
                  </div>
                  <p className="gtm-studios-pricing-card-description">
                    End-to-end community and content management with platform-specific strategy and performance loops to drive real engagement.
                  </p>
                  <div className="gtm-studios-pricing-price">
                    <span className="gtm-studios-pricing-amount">$15K</span>
                    <span className="gtm-studios-pricing-period">/month</span>
                  </div>
                  <button className="gtm-studios-pricing-button">Get Started</button>
                </div>
              </div>

              <div className="gtm-studios-pricing-cta">
                <div className="gtm-studios-pricing-cta-row">
                  <h3 className="gtm-studios-pricing-cta-heading">Can't find your exact fit?</h3>
                  <p className="gtm-studios-pricing-cta-text">
                    No problem, every brief is unique. Tell us about yours and we'll build a tailored proposal asap. Book a slot and we'll be on it.
                  </p>
                </div>
                <button className="gtm-studios-pricing-cta-button">Reach Us</button>
              </div>
            </div>
          </section>

          {/* Testimonials Section */}
          <section className="gtm-studios-testimonials">
            <div className="gtm-studios-testimonials-container">
              <div className="gtm-studios-testimonials-tag">
                <span className="gtm-studios-testimonials-dot"></span>
                <span>Testimonials</span>
              </div>
              <h2 className="gtm-studios-testimonials-heading">The Voices Behind Our Network</h2>
              
              <div className="gtm-studios-testimonials-carousel">
                <div 
                  className={`gtm-studios-testimonial-card ${activeTestimonial === 0 ? 'active' : ''}`}
                  onClick={() => setActiveTestimonial(0)}
                >
                  <div className="gtm-studios-testimonial-content">
                    <p className="gtm-studios-testimonial-quote">
                      "This Web3 app has completely revolutionized the way we do business. The decentralized features have improved security, and the smart contracts are seamless."
                    </p>
                    <div className="gtm-studios-testimonial-author">
                      <div className="gtm-studios-testimonial-avatar"></div>
                      <span className="gtm-studios-testimonial-name">Daniel Garcia</span>
                    </div>
                  </div>
                  <div className="gtm-studios-testimonial-quote-mark">"</div>
                </div>

                <div 
                  className={`gtm-studios-testimonial-card ${activeTestimonial === 1 ? 'active' : ''}`}
                  onClick={() => setActiveTestimonial(1)}
                >
                  <div className="gtm-studios-testimonial-content">
                    <p className="gtm-studios-testimonial-quote">
                      "The platform we integrated has drastically improved our workflow and user interaction."
                    </p>
                    <div className="gtm-studios-testimonial-author">
                      <div className="gtm-studios-testimonial-avatar"></div>
                      <span className="gtm-studios-testimonial-name">Alex Johnson</span>
                    </div>
                  </div>
                  <div className="gtm-studios-testimonial-quote-mark">"</div>
                </div>

                <div 
                  className={`gtm-studios-testimonial-card ${activeTestimonial === 2 ? 'active' : ''}`}
                  onClick={() => setActiveTestimonial(2)}
                >
                  <div className="gtm-studios-testimonial-content">
                    <p className="gtm-studios-testimonial-quote">
                      "This Web3 app has completely changed the way we do business. The features have improved our contracts and made everything seamless."
                    </p>
                    <div className="gtm-studios-testimonial-author">
                      <div className="gtm-studios-testimonial-avatar"></div>
                      <span className="gtm-studios-testimonial-name">Sarah Mitchell</span>
                    </div>
                  </div>
                  <div className="gtm-studios-testimonial-quote-mark">"</div>
                </div>
              </div>

              <div className="gtm-studios-testimonials-indicators">
                <div 
                  className={`gtm-studios-testimonial-indicator ${activeTestimonial === 0 ? 'active' : ''}`}
                  onClick={() => setActiveTestimonial(0)}
                >
                  <div className="gtm-studios-testimonial-indicator-avatar"></div>
                </div>
                <div 
                  className={`gtm-studios-testimonial-indicator ${activeTestimonial === 1 ? 'active' : ''}`}
                  onClick={() => setActiveTestimonial(1)}
                >
                  <div className="gtm-studios-testimonial-indicator-avatar"></div>
                </div>
                <div 
                  className={`gtm-studios-testimonial-indicator ${activeTestimonial === 2 ? 'active' : ''}`}
                  onClick={() => setActiveTestimonial(2)}
                >
                  <div className="gtm-studios-testimonial-indicator-avatar"></div>
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
        </div>
      )}

      {currentPage === 'fellowship' && (
        <div className="fellowship-page">
          {/* Coming Soon Section */}
          <section className="fellowship-coming-soon-section">
            <div className="fellowship-coming-soon-container">
              <h1 className="fellowship-coming-soon-title">Coming soon</h1>
              <div className="fellowship-coming-soon-text">
                <p className="fellowship-coming-soon-paragraph">
                  The next generation of web3 builders will be inspired and educated by the Crib Fellowship. Become a member by joining the waitlist for this invaluable program that focuses on developing your skills and advancing your career
                </p>
                <p className="fellowship-coming-soon-paragraph">
                  Our blog and newsletter offer the latest trends, insights, and analysis to help overcome web3 difficulties. Currently available for members, but public access coming soon in Q3 2026.
                </p>
              </div>
              <form className="fellowship-waitlist-form" onSubmit={(e) => { e.preventDefault(); }}>
                <div className="fellowship-form-row">
                  <div className="fellowship-form-field">
                    <label htmlFor="waitlist-name" className="fellowship-form-label">Name</label>
                    <input
                      type="text"
                      id="waitlist-name"
                      className="fellowship-form-input"
                      placeholder="Enter your name"
                      value={waitlistName}
                      onChange={(e) => setWaitlistName(e.target.value)}
                    />
                  </div>
                  <div className="fellowship-form-field">
                    <label htmlFor="waitlist-email" className="fellowship-form-label">Email</label>
                    <input
                      type="email"
                      id="waitlist-email"
                      className="fellowship-form-input"
                      placeholder="Enter your email"
                      value={waitlistEmail}
                      onChange={(e) => setWaitlistEmail(e.target.value)}
                    />
                  </div>
                </div>
                <button type="submit" className="fellowship-submit-button">Submit</button>
              </form>
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
        </div>
      )}

      {currentPage === 'learns' && (
        <div className="learns-page">
          {/* Main Content Section */}
          <section className="learns-main-section">
            <div className="learns-container">
              <div className="learns-main">
                <div className="learns-content">
                  <div className="learns-tag">
                    <span className="learns-tag-icon"></span>
                    <span>Learns</span>
                  </div>
                  <h1 className="learns-heading">Get Fresh Resources From Experts</h1>
                  <p className="learns-description">
                    Playbooks, Podcasts, Recaps and Market deep-dives audios from our global network.
                  </p>
                  <button className="learns-stay-tuned-button">Stay Tuned</button>
                  
                  <div className="learns-cards">
                    <div className="learns-card">
                      <div className="learns-card-image-wrapper">
                        <img src={liquid1Image} alt="How to Build a Calming Night Routine" className="learns-card-image" />
                        <div className="learns-card-icon">→</div>
                      </div>
                      <h3 className="learns-card-title">How to Build a Calming Night Routine</h3>
                    </div>
                    
                    <div className="learns-card">
                      <div className="learns-card-image-wrapper">
                        <img src={liquid2Image} alt="Why Digital Detox Improves Mental Clarity" className="learns-card-image" />
                        <div className="learns-card-icon">→</div>
                      </div>
                      <h3 className="learns-card-title">Why Digital Detox Improves Mental Clarity</h3>
                    </div>
                  </div>
                </div>
                <div className="learns-feature">
                  <img src={liquidImage} alt="The Science Behind Deep Sleep" className="learns-feature-image" />
                  <h3 className="learns-feature-title">The Science Behind Deep Sleep</h3>
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
        </div>
      )}

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
