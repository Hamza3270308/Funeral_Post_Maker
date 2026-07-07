'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Trash2, Edit, LayoutDashboard, FileStack, Palette, Settings } from 'lucide-react';

interface Template {
  _id: string;
  title: string;
  category: string;
  status: 'draft' | 'active';
  background: {
    type: 'color' | 'image' | 'gradient';
    value: string;
  };
  thumbnailUrl?: string;
}

export default function TemplatesPage() {
  const [templates, setTemplates] = useState<Template[]>([]);
  const [refreshKey, setRefreshKey] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    let isMounted = true;
    fetch('http://127.0.0.1:5001/api/templates/admin')
      .then((response) => {
        if (response.ok) {
          return response.json();
        }
        throw new Error('Failed to fetch templates');
      })
      .then((data: Template[]) => {
        if (isMounted) {
          setTemplates(data);
          setIsLoading(false);
        }
      })
      .catch((error) => {
        console.error('Failed to load templates:', error);
        if (isMounted) {
          setIsLoading(false);
        }
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
        setIsLoading(true);
        setRefreshKey((prev) => prev + 1);
      }
    } catch (error) {
      console.error('Failed to delete template:', error);
    }
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
            <Link href="/templates" className="active">
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
        <div className="header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' }}>
          <h1>Saved Templates</h1>
          <Link href="/creator" className="btn btn-primary" style={{ textDecoration: 'none' }}>
            + Create New
          </Link>
        </div>

        {isLoading ? (
          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '50px', color: 'var(--text-secondary)' }}>
            Loading templates...
          </div>
        ) : templates.length === 0 ? (
          <div className="card" style={{ textAlign: 'center', padding: '60px 20px', color: 'var(--text-secondary)' }}>
            <p style={{ fontSize: '16px', marginBottom: '20px' }}>No templates found. Create your first template in the Creator Studio!</p>
            <Link href="/creator" className="btn btn-primary" style={{ textDecoration: 'none' }}>
              Open Creator Studio
            </Link>
          </div>
        ) : (
          <div>
            {/* Category Pills & Search */}
            <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'center', gap: '15px', marginBottom: '30px' }}>
              <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '4px', maxWidth: '100%' }}>
                {['All', 'Traditional', 'Modern', 'Floral', 'Spiritual', 'Classic'].map(cat => (
                  <button
                    key={cat}
                    onClick={() => setCategoryFilter(cat)}
                    className={`btn ${categoryFilter === cat ? 'btn-primary' : 'btn-secondary'}`}
                    style={{
                      padding: '8px 16px',
                      fontSize: '13px',
                      fontWeight: '600',
                      background: categoryFilter === cat ? 'var(--accent-color)' : 'white',
                      color: categoryFilter === cat ? 'white' : 'var(--text-primary)',
                      border: '1px solid var(--border-color)',
                      borderRadius: '20px',
                      cursor: 'pointer',
                      whiteSpace: 'nowrap'
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
                  padding: '8px 16px',
                  borderRadius: '20px',
                  border: '1px solid var(--border-color)',
                  width: '100%',
                  maxWidth: '300px',
                  fontSize: '13px'
                }}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '25px' }}>
              {templates
                .filter(t => {
                  const matchesCategory = categoryFilter === 'All' || t.category?.toLowerCase() === categoryFilter.toLowerCase();
                  const matchesSearch = t.title?.toLowerCase().includes(searchQuery.toLowerCase());
                  return matchesCategory && matchesSearch;
                })
                .map((template) => {
                  const hasBgImage = template.background && template.background.type === 'image';
                  const bgValue = template.background ? template.background.value : '#FFFFFF';
                  
                  return (
                    <div key={template._id} className="card" style={{ display: 'flex', flexDirection: 'column', padding: '0', overflow: 'hidden', height: '100%', border: '1px solid var(--border-color)' }}>
                      {/* Thumbnail Preview */}
                      <div style={{ 
                        height: '240px', 
                        background: hasBgImage ? `url(${bgValue}) center/cover` : bgValue,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        borderBottom: '1px solid var(--border-color)',
                        position: 'relative'
                      }}>
                        {/* Status Badge */}
                        <span style={{
                          position: 'absolute',
                          top: '12px',
                          right: '12px',
                          padding: '4px 8px',
                          borderRadius: '4px',
                          fontSize: '11px',
                          fontWeight: 'bold',
                          textTransform: 'uppercase',
                          background: template.status === 'active' ? '#D1FAE5' : '#FEF3C7',
                          color: template.status === 'active' ? '#065F46' : '#92400E'
                        }}>
                          {template.status}
                        </span>
                        
                        {!hasBgImage && !bgValue && (
                          <span style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>No Preview</span>
                        )}
                      </div>

                      {/* Template Details */}
                      <div style={{ padding: '20px', display: 'flex', flexDirection: 'column', flex: 1 }}>
                        <h3 style={{ margin: '0 0 5px 0', fontSize: '18px', color: 'var(--text-primary)' }}>
                          {template.title || 'Untitled Template'}
                        </h3>
                        <span style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '20px', display: 'block' }}>
                          Category: {template.category || 'General'}
                        </span>

                        {/* Action Buttons */}
                        <div style={{ display: 'flex', gap: '10px', marginTop: 'auto' }}>
                          <Link 
                            href={`/creator?id=${template._id}`} 
                            className="btn btn-primary" 
                            style={{ flex: 1, textDecoration: 'none', gap: '8px', fontSize: '14px' }}
                          >
                            <Edit size={14} style={{ marginRight: '5px' }} /> Edit
                          </Link>
                          <button 
                            onClick={(e) => handleDelete(template._id, e)} 
                            className="btn" 
                            style={{ 
                              background: '#FEE2E2', 
                              color: '#EF4444', 
                              border: 'none', 
                              padding: '10px', 
                              borderRadius: 'var(--radius-md)',
                              cursor: 'pointer'
                            }}
                            title="Delete Template"
                          >
                            <Trash2 size={16} />
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
