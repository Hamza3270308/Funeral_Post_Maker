'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Trash2, Edit, LayoutDashboard, FileStack, Palette, Settings } from 'lucide-react';

interface Template {
  _id: string;
  title: string;
  thumbnailUrl?: string;
  status: 'draft' | 'active';
  background: {
    type: 'color' | 'image' | 'gradient';
    value: string;
  };
}

export default function TemplatesPage() {
  const [templates, setTemplates] = useState<Template[]>([]);
  const [refreshKey, setRefreshKey] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    let isMounted = true;
    const apiBase = '';
    fetch(`${apiBase}/api/templates/admin`, { cache: 'no-store' })
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
      const apiBase = '';
      const response = await fetch(`${apiBase}/api/templates/${id}`, { method: 'DELETE' });
      if (response.ok) {
        setIsLoading(true);
        setRefreshKey((prev) => prev + 1);
      }
    } catch (error) {
      console.error('Failed to delete template:', error);
    }
  };

  const handleToggleStatus = async (id: string, currentStatus: string, e: React.MouseEvent) => {
    e.preventDefault();
    const newStatus = currentStatus === 'active' ? 'draft' : 'active';
    try {
      const apiBase = '';
      const response = await fetch(`${apiBase}/api/templates/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
      });
      if (response.ok) {
        setRefreshKey((prev) => prev + 1);
      }
    } catch (error) {
      console.error('Failed to toggle status:', error);
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
            {/* Search */}
            <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', marginBottom: '20px' }}>
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
                  const matchesSearch = searchQuery === '' || 
                    (t.title?.toLowerCase() || '').includes(searchQuery.toLowerCase());
                  return matchesSearch;
                })
                .map((template) => {
                  const hasBgImage = template.background && template.background.type === 'image';
                  const bgValue = template.background ? template.background.value : '#FFFFFF';
                  
                  return (
                    <div key={template._id} className="card" style={{ display: 'flex', flexDirection: 'column', padding: '0', overflow: 'hidden', height: '100%', border: '1px solid var(--border-color)' }}>
                      {/* Thumbnail Preview */}
                      <div style={{ 
                        height: '240px', 
                        background: template.thumbnailUrl && template.thumbnailUrl !== ''
                            ? `url("${template.thumbnailUrl}") center/contain no-repeat`
                            : (hasBgImage ? `url("${bgValue}") center/cover no-repeat` : bgValue),
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
                        <p style={{ margin: 0, fontSize: '13px', color: 'var(--text-secondary)' }}>
                          Status: <span style={{ fontWeight: '500', color: template.status === 'active' ? '#4caf50' : '#ff9800' }}>{template.status || 'draft'}</span>
                        </p>

                        {/* Action Buttons */}
                        <div style={{ display: 'flex', gap: '8px', marginTop: 'auto' }}>
                          <Link 
                            href={`/creator?id=${template._id}`} 
                            className="btn btn-primary" 
                            style={{ flex: 1, textDecoration: 'none', gap: '6px', fontSize: '13px' }}
                          >
                            <Edit size={14} style={{ marginRight: '4px' }} /> Edit
                          </Link>
                          <button
                            onClick={(e) => handleToggleStatus(template._id, template.status, e)}
                            className="btn"
                            style={{
                              background: template.status === 'active' ? '#FEF3C7' : '#D1FAE5',
                              color: template.status === 'active' ? '#92400E' : '#065F46',
                              border: 'none',
                              padding: '8px 10px',
                              borderRadius: 'var(--radius-md)',
                              cursor: 'pointer',
                              fontSize: '12px',
                              fontWeight: 'bold'
                            }}
                            title={template.status === 'active' ? "Unpublish to Draft" : "Publish to Active"}
                          >
                            {template.status === 'active' ? 'Unpublish' : 'Publish'}
                          </button>
                          <button 
                            onClick={(e) => handleDelete(template._id, e)} 
                            className="btn" 
                            style={{ 
                              background: '#FEE2E2', 
                              color: '#EF4444', 
                              border: 'none', 
                              padding: '8px 10px', 
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
