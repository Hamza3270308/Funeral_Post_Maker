'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

export default function Home() {
  const router = useRouter();
  const [customWidth, setCustomWidth] = useState('1080');
  const [customHeight, setCustomHeight] = useState('1080');
  const [stats, setStats] = useState({ active: 0, drafts: 0, downloads: 0 });
  const [templates, setTemplates] = useState<any[]>([]);

  const fetchStats = async () => {
    try {
      const response = await fetch('http://localhost:5000/api/templates');
      if (response.ok) {
        const data = await response.json();
        setTemplates(data);
        setStats({
          active: data.length || 0,
          drafts: 0,
          downloads: 0
        });
      }
    } catch (error) {
      console.error('Failed to fetch templates:', error);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this template?')) return;
    try {
      const response = await fetch(`http://localhost:5000/api/templates/${id}`, { method: 'DELETE' });
      if (response.ok) {
        fetchStats();
      }
    } catch (error) {
      console.error('Failed to delete template:', error);
    }
  };

  const handleCustomCreate = () => {
    router.push(`/creator?width=${customWidth}&height=${customHeight}`);
  };

  return (
    <div className="layout">
      {/* Sidebar */}
      <aside className="sidebar">
        <h2>Post Maker</h2>
        <ul className="nav-links">
          <li><Link href="/" className="active">Dashboard</Link></li>
          <li><Link href="/templates">Templates</Link></li>
          <li><Link href="/creator">Template Creator</Link></li>
          <li><Link href="/settings">Settings</Link></li>
        </ul>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        <div className="header">
          <h1>Dashboard Overview</h1>
        </div>

        <div className="card" style={{ marginBottom: '30px', background: 'rgba(74, 101, 114, 0.05)', border: '1px solid var(--primary-color)' }}>
          <h3>Create a New Template</h3>
          <p style={{ color: 'var(--text-secondary)', marginTop: '10px', marginBottom: '20px' }}>
            Choose a standard size or enter custom dimensions.
          </p>
          
          <div style={{ display: 'flex', gap: '15px', marginBottom: '20px' }}>
            <Link href="/creator?width=1080&height=1920" className="btn btn-primary" style={{ textDecoration: 'none' }}>
              Standard Mobile (1080x1920)
            </Link>
            <Link href="/creator?width=1080&height=1080" className="btn" style={{ textDecoration: 'none', background: 'var(--surface-color)', color: 'var(--text-primary)', border: '1px solid var(--border-color)' }}>
              Square Size (1080x1080)
            </Link>
          </div>

          {/* Custom Size Form */}
          <div style={{ display: 'flex', gap: '10px', alignItems: 'flex-end', borderTop: '1px solid var(--border-color)', paddingTop: '20px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '5px' }}>Custom Width</label>
              <input 
                type="number" 
                value={customWidth} 
                onChange={(e) => setCustomWidth(e.target.value)} 
                style={{ padding: '8px', border: '1px solid var(--border-color)', borderRadius: '4px', width: '100px' }}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '5px' }}>Custom Height</label>
              <input 
                type="number" 
                value={customHeight} 
                onChange={(e) => setCustomHeight(e.target.value)} 
                style={{ padding: '8px', border: '1px solid var(--border-color)', borderRadius: '4px', width: '100px' }}
              />
            </div>
            <button onClick={handleCustomCreate} className="btn" style={{ background: 'var(--text-primary)', color: 'white', border: 'none' }}>
              Create Custom
            </button>
          </div>
        </div>
        
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '20px', marginTop: '20px', marginBottom: '30px' }}>
           <div className="card">
             <h3 style={{ color: 'var(--primary-color)', margin: 0, fontSize: '24px' }}>{stats.active}</h3>
             <p style={{ color: 'var(--text-secondary)', margin: '5px 0 0 0' }}>Active Templates</p>
           </div>
           <div className="card">
             <h3 style={{ color: 'var(--primary-color)', margin: 0, fontSize: '24px' }}>{stats.drafts}</h3>
             <p style={{ color: 'var(--text-secondary)', margin: '5px 0 0 0' }}>Drafts</p>
           </div>
           <div className="card">
             <h3 style={{ color: 'var(--primary-color)', margin: 0, fontSize: '24px' }}>{stats.downloads}</h3>
             <p style={{ color: 'var(--text-secondary)', margin: '5px 0 0 0' }}>Total Downloads</p>
           </div>
        </div>

        <div className="card">
          <h3 style={{ marginBottom: '15px' }}>Recent Templates</h3>
          {templates.length === 0 ? (
            <p style={{ color: 'var(--text-secondary)' }}>No templates found. Create one above!</p>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {templates.map(t => (
                <div key={t._id} style={{ display: 'flex', justifyContent: 'space-between', padding: '15px', border: '1px solid var(--border-color)', borderRadius: '8px' }}>
                  <div>
                    <h4 style={{ margin: '0 0 5px 0' }}>{t.title || 'Untitled Template'}</h4>
                    <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Category: {t.category || 'General'}</span>
                  </div>
                  <button onClick={() => handleDelete(t._id)} className="btn" style={{ background: '#FEE2E2', color: '#EF4444', border: 'none', padding: '5px 10px' }}>
                    Delete
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
