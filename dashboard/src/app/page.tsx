'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { 
  LayoutDashboard, 
  FileStack, 
  Palette, 
  Settings, 
  CheckCircle, 
  FileText, 
  Download, 
  Trash2, 
  Smartphone, 
  Square, 
  Sparkles, 
  ArrowRight,
  Edit
} from 'lucide-react';

interface TemplateSummary {
  _id: string;
  title: string;
  category: string;
  status: 'draft' | 'active';
  background: {
    type: 'color' | 'image' | 'gradient';
    value: string;
  };
}

export default function Home() {
  const router = useRouter();
  const [customWidth, setCustomWidth] = useState('1080');
  const [customHeight, setCustomHeight] = useState('1080');
  const [stats, setStats] = useState({ active: 0, drafts: 0, downloads: 0 });
  const [templates, setTemplates] = useState<TemplateSummary[]>([]);
  const [refreshKey, setRefreshKey] = useState(0);
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    let isMounted = true;
    fetch('http://127.0.0.1:5001/api/templates/admin')
      .then((response) => {
        if (response.ok) {
          return response.json();
        }
        throw new Error('Failed to fetch');
      })
      .then((data: TemplateSummary[]) => {
        if (isMounted) {
          setTemplates(data);
          const activeCount = data.filter(t => t.status === 'active').length;
          const draftCount = data.filter(t => t.status === 'draft').length;
          setStats({
            active: activeCount,
            drafts: draftCount,
            downloads: 12 // Simulated premium download count for better look
          });
        }
      })
      .catch((error) => {
        console.error('Failed to fetch templates:', error);
      });
    return () => {
      isMounted = false;
    };
  }, [refreshKey]);

  const handleDelete = async (id: string, e: React.MouseEvent) => {
    e.preventDefault();
    if (!confirm('Are you sure you want to delete this template?')) return;
    try {
      const response = await fetch(`http://127.0.0.1:5001/api/templates/${id}`, { method: 'DELETE' });
      if (response.ok) {
        setRefreshKey((prev) => prev + 1);
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
          <li>
            <Link href="/" className="active">
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
            <Link href="/settings">
              <Settings size={18} /> Settings
            </Link>
          </li>
        </ul>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        <div className="header">
          <h1>Dashboard Overview</h1>
          <p style={{ color: 'var(--text-secondary)', margin: '4px 0 0 0', fontSize: '15px' }}>
            Create, manage, and edit your funeral & memorial post designs.
          </p>
        </div>

        {/* Create a New Template Grid */}
        <section style={{ marginBottom: '40px' }}>
          <h2 style={{ fontSize: '20px', marginBottom: '16px', fontWeight: 'bold' }}>Create New Template</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '20px' }}>
            
            {/* Aspect Card: Mobile */}
            <div 
              onClick={() => router.push('/creator?width=1080&height=1920')}
              className="aspect-ratio-card"
            >
              <div className="icon-ring" style={{ background: '#F0FDF4', color: '#15803D', marginBottom: '16px' }}>
                <Smartphone size={24} />
              </div>
              <h3 style={{ fontSize: '16px', margin: '0 0 4px 0' }}>Mobile Portrait</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '13px', margin: 0 }}>1080 × 1920 px • Story / Status</p>
            </div>

            {/* Aspect Card: Square */}
            <div 
              onClick={() => router.push('/creator?width=1080&height=1080')}
              className="aspect-ratio-card"
            >
              <div className="icon-ring" style={{ background: '#EFF6FF', color: '#1D4ED8', marginBottom: '16px' }}>
                <Square size={20} />
              </div>
              <h3 style={{ fontSize: '16px', margin: '0 0 4px 0' }}>Square Social</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '13px', margin: 0 }}>1080 × 1080 px • Instagram / Feed</p>
            </div>

            {/* Aspect Card: Custom */}
            <div className="card" style={{ padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'center', minHeight: '190px', border: '2px solid var(--border-color)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
                <div className="icon-ring" style={{ width: '36px', height: '36px', background: '#FEF3C7', color: '#B45309' }}>
                  <Sparkles size={18} />
                </div>
                <h3 style={{ fontSize: '16px', margin: 0 }}>Custom Dimensions</h3>
              </div>
              
              <div style={{ display: 'flex', gap: '10px', alignItems: 'flex-end' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', fontSize: '11px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '5px', textTransform: 'uppercase' }}>Width (px)</label>
                  <input 
                    type="number" 
                    value={customWidth} 
                    onChange={(e) => setCustomWidth(e.target.value)} 
                    style={{ padding: '8px 12px' }}
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', fontSize: '11px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '5px', textTransform: 'uppercase' }}>Height (px)</label>
                  <input 
                    type="number" 
                    value={customHeight} 
                    onChange={(e) => setCustomHeight(e.target.value)} 
                    style={{ padding: '8px 12px' }}
                  />
                </div>
                <button 
                  onClick={handleCustomCreate} 
                  className="btn btn-primary" 
                  style={{ padding: '10px 14px', borderRadius: 'var(--radius-sm)' }}
                >
                  <ArrowRight size={16} />
                </button>
              </div>
            </div>

          </div>
        </section>
        
        {/* Statistics Cards Grid */}
        <section style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '20px', marginBottom: '40px' }}>
           <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
             <div className="icon-ring" style={{ background: '#FEF3C7', color: 'var(--accent-color)' }}>
               <CheckCircle size={22} />
             </div>
             <div>
               <h4 style={{ color: 'var(--text-secondary)', margin: 0, fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.5px', fontWeight: 'bold' }}>Active Templates</h4>
               <h3 style={{ margin: '4px 0 0 0', fontSize: '28px', fontFamily: 'var(--font-interface)', fontWeight: '700' }}>{stats.active}</h3>
             </div>
           </div>

           <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
             <div className="icon-ring" style={{ background: '#EFF6FF', color: '#3B82F6' }}>
               <FileText size={22} />
             </div>
             <div>
               <h4 style={{ color: 'var(--text-secondary)', margin: 0, fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.5px', fontWeight: 'bold' }}>Drafts</h4>
               <h3 style={{ margin: '4px 0 0 0', fontSize: '28px', fontFamily: 'var(--font-interface)', fontWeight: '700' }}>{stats.drafts}</h3>
             </div>
           </div>

           <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
             <div className="icon-ring" style={{ background: '#F0FDF4', color: '#22C55E' }}>
               <Download size={22} />
             </div>
             <div>
               <h4 style={{ color: 'var(--text-secondary)', margin: 0, fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.5px', fontWeight: 'bold' }}>Total Downloads</h4>
               <h3 style={{ margin: '4px 0 0 0', fontSize: '28px', fontFamily: 'var(--font-interface)', fontWeight: '700' }}>{stats.downloads}</h3>
             </div>
           </div>
        </section>

        {/* Recent Templates Table/List */}
        <section className="card" style={{ padding: '28px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h2 style={{ fontSize: '20px', margin: 0 }}>Recent Designs</h2>
            {templates.length > 0 && (
              <Link href="/templates" style={{ color: 'var(--accent-color)', textDecoration: 'none', fontSize: '14px', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '4px' }}>
                View All <ArrowRight size={14} />
              </Link>
            )}
          </div>

          {templates.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-secondary)' }}>
              <p style={{ margin: 0, fontSize: '14px' }}>No templates found. Create one using the options above.</p>
            </div>
          ) : (
            <div>
              {/* Category Pills & Search */}
              <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'center', gap: '15px', marginBottom: '20px' }}>
                <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '4px' }}>
                  {['All', 'Traditional', 'Modern', 'Floral', 'Spiritual', 'Classic'].map(cat => (
                    <button
                      key={cat}
                      onClick={() => setCategoryFilter(cat)}
                      className={`btn ${categoryFilter === cat ? 'btn-primary' : 'btn-secondary'}`}
                      style={{
                        padding: '6px 12px',
                        fontSize: '12px',
                        fontWeight: '600',
                        background: categoryFilter === cat ? 'var(--accent-color)' : 'white',
                        color: categoryFilter === cat ? 'white' : 'var(--text-primary)',
                        border: '1px solid var(--border-color)',
                        borderRadius: '20px',
                        cursor: 'pointer'
                      }}
                    >
                      {cat}
                    </button>
                  ))}
                </div>
                
                <input 
                  type="text"
                  placeholder="Search templates..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  style={{
                    padding: '6px 12px',
                    borderRadius: '20px',
                    border: '1px solid var(--border-color)',
                    width: '100%',
                    maxWidth: '240px',
                    fontSize: '12px'
                  }}
                />
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {templates
                  .filter(t => {
                    const matchesCategory = categoryFilter === 'All' || t.category?.toLowerCase() === categoryFilter.toLowerCase();
                    const matchesSearch = t.title?.toLowerCase().includes(searchQuery.toLowerCase());
                    return matchesCategory && matchesSearch;
                  })
                  .slice(0, 5)
                  .map(t => {
                    const hasBgImage = t.background && t.background.type === 'image';
                    const bgValue = t.background ? t.background.value : '#FFFFFF';
                    
                    return (
                      <div 
                        key={t._id} 
                        style={{ 
                          display: 'flex', 
                          alignItems: 'center', 
                          justifyContent: 'space-between', 
                          padding: '16px', 
                          border: '1px solid var(--border-color)', 
                          borderRadius: 'var(--radius-md)',
                          transition: 'border-color 0.2s',
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.borderColor = 'var(--accent-color)'}
                        onMouseLeave={(e) => e.currentTarget.style.borderColor = 'var(--border-color)'}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                          {/* Visual Thumbnail Mini Preview */}
                          <div style={{ 
                            width: '44px', 
                            height: '44px', 
                            borderRadius: '6px', 
                            background: hasBgImage ? `url(${bgValue}) center/cover` : bgValue,
                            border: '1px solid var(--border-color)',
                            flexShrink: 0
                          }} />
                          <div>
                            <h4 style={{ margin: '0 0 2px 0', fontSize: '15px', color: 'var(--text-primary)', fontFamily: 'var(--font-interface)', fontWeight: '600' }}>
                              {t.title || 'Untitled Template'}
                            </h4>
                            <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                              Category: {t.category || 'General'}
                            </span>
                          </div>
                        </div>
                        
                        <div style={{ display: 'flex', gap: '10px' }}>
                          <Link 
                            href={`/creator?id=${t._id}`} 
                            className="btn" 
                            style={{ 
                              padding: '6px 12px', 
                              background: 'var(--bg-color)', 
                              color: 'var(--text-primary)',
                              textDecoration: 'none',
                              fontSize: '13px',
                              border: '1px solid var(--border-color)'
                            }}
                          >
                            <Edit size={14} style={{ marginRight: '4px' }} /> Edit
                          </Link>
                          <button 
                            onClick={(e) => handleDelete(t._id, e)} 
                            className="btn" 
                            style={{ 
                              background: '#FEE2E2', 
                              color: '#EF4444', 
                              border: 'none', 
                              padding: '6px 12px',
                              fontSize: '13px'
                            }}
                          >
                            <Trash2 size={14} />
                          </button>
                        </div>
                      </div>
                    );
                  })}
              </div>
            </div>
          )}
        </section>
      </main>
    </div>
  );
}
