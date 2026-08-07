'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { 
  LayoutDashboard, 
  FileStack, 
  Palette, 
  Settings, 
  Save, 
  Database, 
  Sliders, 
  Server, 
  CheckCircle
} from 'lucide-react';

export default function SettingsPage() {
  // Load settings from localStorage or defaults
  const [appTitle, setAppTitle] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('settings_app_title') || 'Funeral Post Maker';
    }
    return 'Funeral Post Maker';
  });
  const [defaultWidth, setDefaultWidth] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('settings_default_width') || '1080';
    }
    return '1080';
  });
  const [defaultHeight, setDefaultHeight] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('settings_default_height') || '1920';
    }
    return '1920';
  });
  const [backendUrl, setBackendUrl] = useState(() => {
    // If not set, use the environment variable provided by Coolify Docker Compose, or the live backend by default
    if (typeof window !== 'undefined') {
      return localStorage.getItem('settings_backend_url') || process.env.NEXT_PUBLIC_API_URL || 'http://q14c5cff8kaukmncrx1w60rf.31.97.48.137.sslip.io';
    }
    return process.env.NEXT_PUBLIC_API_URL || 'http://q14c5cff8kaukmncrx1w60rf.31.97.48.137.sslip.io';
  });
  const [primaryColor, setPrimaryColor] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('settings_primary_color') || '#1E252B';
    }
    return '#1E252B';
  });
  const [accentColor, setAccentColor] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('settings_accent_color') || '#C5A880';
    }
    return '#C5A880';
  });
  const [isSaved, setIsSaved] = useState(false);
  const [dbStatus, setDbStatus] = useState<'checking' | 'connected' | 'error'>('checking');

  useEffect(() => {
    const apiBase = '';
    fetch(`${apiBase}/api/templates/admin`)
      .then((res) => {
        if (res.ok) setDbStatus('connected');
        else setDbStatus('error');
      })
      .catch(() => {
        setDbStatus('error');
      });
  }, []);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (typeof window !== 'undefined') {
      localStorage.setItem('settings_app_title', appTitle);
      localStorage.setItem('settings_default_width', defaultWidth);
      localStorage.setItem('settings_default_height', defaultHeight);
      localStorage.setItem('settings_backend_url', backendUrl);
      localStorage.setItem('settings_primary_color', primaryColor);
      localStorage.setItem('settings_accent_color', accentColor);
    }
    setIsSaved(true);
    setTimeout(() => setIsSaved(false), 3000);
  };

  return (
    <div className="layout">
      {/* Sidebar */}
      <aside className="sidebar">
        <h2>Post Maker</h2>
        <ul className="nav-links">
          <li>
            <Link href="/">
              <LayoutDashboard size={18} /> Dashboard
            </Link>
          </li>
          <li>
            <Link href="/templates">
              <FileStack size={18} /> Templates
            </Link>
          </li>
          <li>
            <Link href="/creator">
              <Palette size={18} /> Template Creator
            </Link>
          </li>
          <li>
            <Link href="/settings" className="active">
              <Settings size={18} /> Settings
            </Link>
          </li>
        </ul>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        <div className="header">
          <h1>System Settings</h1>
          <p style={{ color: 'var(--text-secondary)', margin: '4px 0 0 0', fontSize: '15px' }}>
            Configure default preferences, canvas settings, and API integrations.
          </p>
        </div>

        <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '24px', maxWidth: '800px' }}>
          
          {/* Settings Section: General Preferences */}
          <section className="card" style={{ padding: '28px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px', borderBottom: '1px solid var(--border-color)', paddingBottom: '12px' }}>
              <Sliders size={20} style={{ color: 'var(--accent-color)' }} />
              <h2 style={{ fontSize: '18px', margin: 0 }}>General Preferences</h2>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div className="input-group" style={{ margin: 0 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '6px', textTransform: 'uppercase' }}>Application Title</label>
                <input 
                  type="text" 
                  value={appTitle} 
                  onChange={(e) => setAppTitle(e.target.value)}
                  placeholder="e.g. Funeral Post Maker"
                  required
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="input-group" style={{ margin: 0 }}>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '6px', textTransform: 'uppercase' }}>Default Canvas Width (px)</label>
                  <input 
                    type="number" 
                    value={defaultWidth} 
                    onChange={(e) => setDefaultWidth(e.target.value)}
                    placeholder="1080"
                    required
                  />
                </div>
                <div className="input-group" style={{ margin: 0 }}>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '6px', textTransform: 'uppercase' }}>Default Canvas Height (px)</label>
                  <input 
                    type="number" 
                    value={defaultHeight} 
                    onChange={(e) => setDefaultHeight(e.target.value)}
                    placeholder="1920"
                    required
                  />
                </div>
              </div>
            </div>
          </section>

          {/* Settings Section: Brand Aesthetics */}
          <section className="card" style={{ padding: '28px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px', borderBottom: '1px solid var(--border-color)', paddingBottom: '12px' }}>
              <Palette size={20} style={{ color: 'var(--accent-color)' }} />
              <h2 style={{ fontSize: '18px', margin: 0 }}>Brand Aesthetics</h2>
            </div>
            
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div className="input-group" style={{ margin: 0 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '6px', textTransform: 'uppercase' }}>Primary Brand Color (Charcoal)</label>
                <div style={{ display: 'flex', gap: '10px' }}>
                  <input 
                    type="color" 
                    value={primaryColor} 
                    onChange={(e) => setPrimaryColor(e.target.value)}
                    style={{ padding: '0', height: '40px', width: '60px', cursor: 'pointer', flexShrink: 0 }}
                  />
                  <input 
                    type="text" 
                    value={primaryColor} 
                    onChange={(e) => setPrimaryColor(e.target.value)}
                    placeholder="#1E252B"
                    required
                  />
                </div>
              </div>
              <div className="input-group" style={{ margin: 0 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '6px', textTransform: 'uppercase' }}>Accent Brand Color (Gold)</label>
                <div style={{ display: 'flex', gap: '10px' }}>
                  <input 
                    type="color" 
                    value={accentColor} 
                    onChange={(e) => setAccentColor(e.target.value)}
                    style={{ padding: '0', height: '40px', width: '60px', cursor: 'pointer', flexShrink: 0 }}
                  />
                  <input 
                    type="text" 
                    value={accentColor} 
                    onChange={(e) => setAccentColor(e.target.value)}
                    placeholder="#C5A880"
                    required
                  />
                </div>
              </div>
            </div>
          </section>

          {/* Settings Section: Integration & Server */}
          <section className="card" style={{ padding: '28px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px', borderBottom: '1px solid var(--border-color)', paddingBottom: '12px' }}>
              <Server size={20} style={{ color: 'var(--accent-color)' }} />
              <h2 style={{ fontSize: '18px', margin: 0 }}>API & Integration Settings</h2>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div className="input-group" style={{ margin: 0 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '6px', textTransform: 'uppercase' }}>Backend API Endpoint URL</label>
                <input 
                  type="text"
                  placeholder="http://localhost:5001"
                  value={backendUrl}
                  onChange={(e) => setBackendUrl(e.target.value)}
                  required
                />
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '20px', padding: '16px', background: 'var(--bg-color)', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-color)' }}>
                <Database size={24} style={{ color: dbStatus === 'connected' ? '#22C55E' : dbStatus === 'error' ? '#EF4444' : 'var(--text-secondary)' }} />
                <div style={{ flex: 1 }}>
                  <h4 style={{ margin: 0, fontSize: '14px', fontWeight: 'bold', color: 'var(--text-primary)' }}>MongoDB Server Status</h4>
                  <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: 'var(--text-secondary)' }}>
                    {dbStatus === 'connected' && 'Successfully connected to backend API database.'}
                    {dbStatus === 'error' && 'Cannot reach backend server. Please verify if npm run dev is running for the backend.'}
                    {dbStatus === 'checking' && 'Verifying database server connection...'}
                  </p>
                </div>
                <div>
                  <span style={{
                    padding: '4px 10px',
                    borderRadius: '20px',
                    fontSize: '11px',
                    fontWeight: 'bold',
                    textTransform: 'uppercase',
                    background: dbStatus === 'connected' ? '#D1FAE5' : dbStatus === 'error' ? '#FEE2E2' : '#E2E8F0',
                    color: dbStatus === 'connected' ? '#065F46' : dbStatus === 'error' ? '#991B1B' : 'var(--text-secondary)'
                  }}>
                    {dbStatus}
                  </span>
                </div>
              </div>
            </div>
          </section>

          {/* Action Buttons */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginTop: '8px' }}>
            <button type="submit" className="btn btn-primary" style={{ padding: '12px 24px' }}>
              <Save size={16} /> Save Settings
            </button>
            
            {isSaved && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#15803D', fontSize: '14px', fontWeight: '600' }}>
                <CheckCircle size={16} /> Preferences saved successfully.
              </div>
            )}
          </div>

        </form>
      </main>
    </div>
  );
}
