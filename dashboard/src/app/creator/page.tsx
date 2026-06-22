'use client';
import { useState, useRef, Suspense, useEffect } from 'react';
import Link from 'next/link';
import { Rnd } from 'react-rnd';
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd';
import { Eye, EyeOff, Trash2, GripVertical, Image as ImageIcon, Type, Square } from 'lucide-react';
import { useSearchParams } from 'next/navigation';

export default function CreatorStudioPage() {
  return (
    <Suspense fallback={<div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', color: 'var(--primary-color)' }}>Loading Studio...</div>}>
      <CreatorStudio />
    </Suspense>
  );
}

function CreatorStudio() {
  const searchParams = useSearchParams();
  const width = searchParams.get('width') || '1080';
  const height = searchParams.get('height') || '1920';

  // Calculate scaled canvas size for the preview area
  const previewHeight = 650;
  const scale = previewHeight / Number(height);
  const previewWidth = Number(width) * scale;

  const [layers, setLayers] = useState([
    { id: '1', type: 'text', content: 'In Loving Memory', x: 120, y: 150, fontSize: 80, color: '#2E3338', fontFamily: 'Inter', width: 800, height: 100, visible: true },
    { id: '2', type: 'text', content: 'John Doe', x: 150, y: 300, fontSize: 140, color: '#4A6572', fontFamily: 'Inter', width: 800, height: 160, visible: true },
    { id: 'date', type: 'text', content: 'Sunrise 1950 - Sunset 2024', x: 120, y: 460, fontSize: 60, color: '#6B7280', fontFamily: 'Inter', width: 840, height: 80, visible: true },
    { id: '3', type: 'image_frame', shape: 'circle', x: 300, y: 600, width: 480, height: 480, visible: true, src: null }
  ]);
  
  const [templateName, setTemplateName] = useState('Custom Template');
  const [background, setBackground] = useState<string | null>(null);
  const [bgOpacity, setBgOpacity] = useState(1);
  const [activeLayerId, setActiveLayerId] = useState<string | null>('2');
  const [editingLayerId, setEditingLayerId] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isNearMargin, setIsNearMargin] = useState(false);
  
  const bgInputRef = useRef<HTMLInputElement>(null);
  const overlayInputRef = useRef<HTMLInputElement>(null);

  const [history, setHistory] = useState<any[]>([]);
  const [historyIndex, setHistoryIndex] = useState(-1);
  const historyIndexRef = useRef(-1);
  const [clipboard, setClipboard] = useState<any | null>(null);

  // Debounced History Save
  useEffect(() => {
    const timer = setTimeout(() => {
      setHistory((prev) => {
        const currentIndex = historyIndexRef.current;
        const lastState = prev[currentIndex];
        const currentState = { layers, background, bgOpacity };
        
        if (lastState && JSON.stringify(lastState) === JSON.stringify(currentState)) {
           return prev;
        }
        
        const newHistory = prev.slice(0, currentIndex + 1);
        newHistory.push(currentState);
        historyIndexRef.current = newHistory.length - 1;
        setHistoryIndex(newHistory.length - 1);
        return newHistory;
      });
    }, 400);
    return () => clearTimeout(timer);
  }, [layers, background, bgOpacity]);

  // Keyboard Shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      if ((e.target as HTMLElement).isContentEditable) return;

      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'c') {
        if (activeLayerId) {
          const layerToCopy = layers.find(l => l.id === activeLayerId);
          if (layerToCopy) setClipboard(layerToCopy);
        }
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'x') {
         if (activeLayerId) {
          const layerToCopy = layers.find(l => l.id === activeLayerId);
          if (layerToCopy) {
            setClipboard(layerToCopy);
            setLayers(layers.filter(l => l.id !== activeLayerId));
            setActiveLayerId(null);
          }
        }
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'v') {
         if (clipboard) {
            const newLayer = { ...clipboard, id: Date.now().toString(), x: clipboard.x + 20, y: clipboard.y + 20 };
            setLayers([...layers, newLayer]);
            setActiveLayerId(newLayer.id);
            setClipboard(newLayer);
         }
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') {
         if (e.shiftKey) {
            if (historyIndexRef.current < history.length - 1) {
                const newIndex = historyIndexRef.current + 1;
                const nextState = history[newIndex];
                historyIndexRef.current = newIndex;
                setHistoryIndex(newIndex);
                setLayers(nextState.layers);
                setBackground(nextState.background);
                setBgOpacity(nextState.bgOpacity);
            }
         } else {
            if (historyIndexRef.current > 0) {
                const newIndex = historyIndexRef.current - 1;
                const prevState = history[newIndex];
                historyIndexRef.current = newIndex;
                setHistoryIndex(newIndex);
                setLayers(prevState.layers);
                setBackground(prevState.background);
                setBgOpacity(prevState.bgOpacity);
            }
         }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [layers, activeLayerId, clipboard, history]);

  const activeLayer = layers.find(l => l.id === activeLayerId);

  // @ts-ignore
  const updateLayer = (id: string, updates: any) => {
    setLayers(layers.map(l => l.id === id ? { ...l, ...updates } : l));
  };

  const handleDragEnd = (result: DropResult) => {
    if (!result.destination) return;
    
    const items = Array.from(layers);
    const [reorderedItem] = items.splice(result.source.index, 1);
    items.splice(result.destination.index, 0, reorderedItem);
    
    setLayers(items);
  };

  const deleteLayer = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setLayers(layers.filter(l => l.id !== id));
    if (activeLayerId === id) setActiveLayerId(null);
  };

  const toggleVisibility = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setLayers(layers.map(l => l.id === id ? { ...l, visible: !l.visible } : l));
  };

  const handleBgUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const url = URL.createObjectURL(e.target.files[0]);
      setBackground(url);
    }
  };

  const handleSave = async () => {
    const payload = {
      title: templateName,
      category: 'General',
      width: Number(width),
      height: Number(height),
      background: background ? 'uploaded_image' : 'color',
      bgOpacity,
      layers: layers.map((l, index) => ({ ...l, zIndex: layers.length - index }))
    };

    try {
      const response = await fetch('http://localhost:5000/api/templates', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      if (response.ok) {
        alert('Template Saved to Database!');
      } else {
        alert('Failed to save to database.');
      }
    } catch (err) {
      console.error(err);
      alert('Error saving template.');
    }
  };

  const getShapeBorderRadius = (shape: string) => {
    if (shape === 'circle' || shape === 'oval') return '50%';
    if (shape === 'rounded-rectangle') return '20px';
    if (shape === 'arch') return '200px 200px 0 0';
    return '0';
  };

  return (
    <div className="creator-layout">
      {/* 
        SWAPPED: Left side is now the Properties & Layers panel
      */}
      <aside className="properties-sidebar" style={{ borderLeft: 'none', borderRight: '1px solid var(--border-color)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', gap: '10px' }}>
           <input 
             value={templateName} 
             onChange={(e) => setTemplateName(e.target.value)}
             style={{ flex: 1, padding: '8px', border: '1px solid var(--border-color)', borderRadius: '4px', fontWeight: 'bold' }}
             placeholder="Template Name"
           />
           <button className="btn btn-primary" onClick={handleSave}>Save</button>
        </div>

        <h3 style={{ fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '10px' }}>Layers (Drag to reorder)</h3>
        
        {/* Drag and Drop Layer List */}
        <DragDropContext onDragEnd={handleDragEnd}>
          <Droppable droppableId="layers">
            {(provided) => (
              <div {...provided.droppableProps} ref={provided.innerRef} style={{ marginBottom: '20px' }}>
                {layers.map((layer, index) => (
                  <Draggable key={layer.id} draggableId={layer.id} index={index}>
                    {(provided) => (
                      <div
                        ref={provided.innerRef}
                        {...provided.draggableProps}
                        className={`layer-item ${activeLayerId === layer.id ? 'active' : ''}`}
                        onClick={() => setActiveLayerId(layer.id)}
                        style={{ ...provided.draggableProps.style, background: 'var(--surface-color)' }}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', overflow: 'hidden' }}>
                          <span {...provided.dragHandleProps} style={{ marginRight: '10px', color: '#9CA3AF', cursor: 'grab' }}>
                            <GripVertical size={16} />
                          </span>
                          <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '120px' }}>
                            {layer.type === 'text' ? layer.content : layer.type === 'shape' ? 'Shape' : 'Image Frame'}
                          </span>
                        </div>
                        <div style={{ display: 'flex', gap: '10px' }}>
                          <span onClick={(e) => toggleVisibility(layer.id, e)} style={{ color: layer.visible ? '#6B7280' : '#D1D5DB', cursor: 'pointer' }}>
                            {layer.visible ? <Eye size={16} /> : <EyeOff size={16} />}
                          </span>
                          <span onClick={(e) => deleteLayer(layer.id, e)} style={{ color: '#EF4444', cursor: 'pointer' }}>
                            <Trash2 size={16} />
                          </span>
                        </div>
                      </div>
                    )}
                  </Draggable>
                ))}
                {provided.placeholder}
              </div>
            )}
          </Droppable>
        </DragDropContext>


      </aside>

      {/* Center Canvas */}
      <main className="canvas-area" onClick={() => setActiveLayerId(null)}>
        <div style={{ marginBottom: '20px', position: 'absolute', top: '20px', color: 'var(--text-secondary)' }}>
           Canvas Size: {width} x {height}
        </div>
        <div 
          style={{
            width: previewWidth,
            height: previewHeight,
            background: 'white',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
            position: 'relative',
            overflow: 'hidden',
            borderRadius: '8px'
          }}
          onMouseMove={(e) => {
            const rect = e.currentTarget.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            const marginX = rect.width * 0.05;
            const marginY = rect.height * 0.05;
            // if mouse is outside the inner 90% zone, show the margin
            const nearEdge = x < marginX || x > rect.width - marginX || y < marginY || y > rect.height - marginY;
            setIsNearMargin(nearEdge);
          }}
          onMouseLeave={() => setIsNearMargin(false)}
        >
          {/* Safe Margin Guide */}
          {(isDragging || isNearMargin) && (
            <div style={{
              position: 'absolute',
              top: '5%', left: '5%', right: '5%', bottom: '5%',
              border: '2px dashed rgba(255, 0, 0, 0.5)',
              pointerEvents: 'none',
              zIndex: 9999
            }} />
          )}
          {background && (
            <div style={{
              position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
              background: `url(${background}) center/cover`,
              opacity: bgOpacity,
              pointerEvents: 'none'
            }} />
          )}
          {[...layers].reverse().map((layer, idx) => {
            if (!layer.visible) return null;
            const zIndex = layers.length - idx;
            
            return (
              <Rnd
                key={layer.id}
                size={layer.type === 'text' ? { width: 'auto', height: 'auto' } : { width: layer.width * scale, height: layer.height * scale }}
                position={{ x: layer.x * scale, y: layer.y * scale }}
                disableDragging={editingLayerId === layer.id}
                onDrag={(e, d) => {
                  if (!isDragging) setIsDragging(true);
                }}
                onDragStop={(e, d) => {
                  setIsDragging(false);
                  updateLayer(layer.id, { x: d.x / scale, y: d.y / scale });
                }}
                lockAspectRatio={true}
                onResizeStop={(e, direction, ref, delta, position) => {
                  setIsDragging(false);
                }}
                onResize={(e, direction, ref, delta, position) => {
                  if (!isDragging) setIsDragging(true);
                  const newWidth = parseInt(ref.style.width) / scale;
                  const newHeight = parseInt(ref.style.height) / scale;
                  const updates: any = {
                    width: newWidth,
                    height: newHeight,
                    x: position.x / scale,
                    y: position.y / scale
                  };
                  
                  if (layer.type === 'text') {
                    const ratio = layer.fontSize / layer.height;
                    updates.fontSize = Math.round(newHeight * ratio);
                  }
                  
                  updateLayer(layer.id, updates);
                }}
                enableResizing={activeLayerId === layer.id ? { top:false, right:false, bottom:false, left:false, topRight:true, bottomRight:true, bottomLeft:true, topLeft:true } : false}
                resizeHandleStyles={{
                  topLeft: { width: '12px', height: '12px', background: 'white', border: '2px solid var(--primary-color)', borderRadius: '50%', left: '-6px', top: '-6px' },
                  topRight: { width: '12px', height: '12px', background: 'white', border: '2px solid var(--primary-color)', borderRadius: '50%', right: '-6px', top: '-6px' },
                  bottomLeft: { width: '12px', height: '12px', background: 'white', border: '2px solid var(--primary-color)', borderRadius: '50%', left: '-6px', bottom: '-6px' },
                  bottomRight: { width: '12px', height: '12px', background: 'white', border: '2px solid var(--primary-color)', borderRadius: '50%', right: '-6px', bottom: '-6px' },
                }}
                onClick={(e) => {
                  e.stopPropagation();
                  setActiveLayerId(layer.id);
                }}
                style={{
                  zIndex,
                  border: activeLayerId === layer.id ? '2px solid var(--primary-color)' : '2px solid transparent',
                  opacity: layer.opacity !== undefined ? layer.opacity : 1,
                  padding: 0
                }}
              >
                <div 
                  onDoubleClick={(e) => {
                    if (layer.type === 'text') {
                      setEditingLayerId(layer.id);
                    }
                  }}
                  style={{
                  width: layer.type === 'text' ? 'max-content' : '100%', 
                  height: layer.type === 'text' ? 'max-content' : '100%',
                  boxSizing: 'border-box',
                  border: layer.borderWidth ? `${layer.borderWidth * scale}px solid ${layer.borderColor || '#000000'}` : 'none',
                  borderRadius: (layer.type === 'image_frame' || layer.type === 'shape') ? getShapeBorderRadius(layer.shape) : '0',
                  overflow: layer.type === 'text' ? 'visible' : 'hidden',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  backgroundColor: layer.type === 'shape' ? (layer.color || '#4A6572') : (layer.type === 'image_frame' ? '#E5E7EB' : 'transparent'),
                  cursor: layer.type === 'text' ? 'text' : undefined
                }}>
                  {layer.type === 'text' && (
                    <span 
                      contentEditable={editingLayerId === layer.id}
                      suppressContentEditableWarning={true}
                      onBlur={(e) => {
                        updateLayer(layer.id, { content: e.currentTarget.innerText });
                        setEditingLayerId(null);
                      }}
                      style={{ 
                        fontSize: layer.fontSize * scale, 
                        color: layer.color,
                        fontFamily: layer.fontFamily + ', sans-serif',
                        fontWeight: layer.fontWeight || 'normal',
                        fontStyle: layer.fontStyle || 'normal',
                        textDecoration: layer.textDecoration || 'none',
                        userSelect: editingLayerId === layer.id ? 'text' : 'none',
                        width: layer.type === 'text' ? 'max-content' : '100%',
                        height: layer.type === 'text' ? 'max-content' : '100%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        lineHeight: 1.2,
                        whiteSpace: 'nowrap',
                        outline: 'none'
                      }}>
                      {layer.content}
                    </span>
                  )}
                  {layer.type === 'image_frame' && (
                    layer.src ? (
                      <img 
                        src={layer.src} 
                        alt="Frame content" 
                        draggable={false}
                        style={{ 
                          width: '100%', 
                          height: '100%', 
                          objectFit: 'cover', 
                          pointerEvents: 'none'
                        }} 
                      />
                    ) : (
                      <ImageIcon color="#9CA3AF" size={40 * scale} />
                    )
                  )}
                  {layer.type === 'image' && (
                    <img 
                      src={layer.src} 
                      alt="Overlay" 
                      draggable={false}
                      style={{ 
                        width: '100%', 
                        height: '100%', 
                        objectFit: 'fill', 
                        pointerEvents: 'none'
                      }} 
                    />
                  )}
                </div>
              </Rnd>
            );
          })}
        </div>
      </main>

      {/* 
        SWAPPED: Right side is now the Add Elements Toolbar
      */}
      <aside className="tools-sidebar" style={{ borderRight: 'none', borderLeft: '1px solid var(--border-color)' }}>
        <Link href="/" style={{ color: 'var(--primary-color)', textDecoration: 'none', marginBottom: '20px', display: 'block', fontWeight: 500 }}>
          &larr; Back to Dashboard
        </Link>
        <h2 style={{ marginBottom: '20px', fontSize: '18px' }}>Add Elements</h2>
        
        <button 
          className="btn" 
          style={{ width: '100%', marginBottom: '10px', border: '1px solid var(--border-color)', background: 'var(--surface-color)' }}
          onClick={() => setLayers([...layers, { id: Date.now().toString(), type: 'text', content: 'New Text', x: 100, y: 100, fontSize: 60, color: '#000', fontFamily: 'Inter', width: 400, height: 100, visible: true }])}
        >
          <Type size={16} style={{ marginRight: '8px' }} /> Add Text
        </button>
        
        <button 
          className="btn" 
          style={{ width: '100%', marginBottom: '10px', border: '1px solid var(--border-color)', background: 'var(--surface-color)' }}
          onClick={() => setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'square', x: 200, y: 200, width: 300, height: 300, visible: true, src: null }])}
        >
          <Square size={16} style={{ marginRight: '8px' }} /> Add Image Frame
        </button>
        
        <button 
          className="btn" 
          style={{ width: '100%', marginBottom: '10px', border: '1px solid var(--border-color)', background: 'var(--surface-color)' }}
          onClick={() => setLayers([...layers, { id: Date.now().toString(), type: 'shape', shape: 'square', color: '#4A6572', x: 250, y: 250, width: 200, height: 200, visible: true }])}
        >
          <Square size={16} style={{ marginRight: '8px', fill: 'currentColor' }} /> Add Shape
        </button>
        
        <input type="file" ref={overlayInputRef} style={{ display: 'none' }} accept="image/*" 
          onChange={(e) => {
            if (e.target.files && e.target.files[0]) {
              const url = URL.createObjectURL(e.target.files[0]);
              setLayers([...layers, { id: Date.now().toString(), type: 'image', src: url, x: 100, y: 100, width: 300, height: 300, visible: true }]);
            }
          }} 
        />
        <button 
          className="btn" 
          style={{ width: '100%', marginBottom: '10px', border: '1px solid var(--border-color)', background: 'var(--surface-color)' }}
          onClick={() => overlayInputRef.current?.click()}
        >
          <ImageIcon size={16} style={{ marginRight: '8px' }} /> Add Image Overlay
        </button>

        <input type="file" ref={bgInputRef} style={{ display: 'none' }} accept="image/*" onChange={handleBgUpload} />
        <button 
          className="btn" 
          style={{ width: '100%', marginBottom: '10px', border: '1px solid var(--border-color)', background: 'var(--surface-color)' }}
          onClick={() => bgInputRef.current?.click()}
        >
          <ImageIcon size={16} style={{ marginRight: '8px' }} /> Change Background
        </button>
        {background && (
          <div className="input-group" style={{ marginBottom: '20px' }}>
            <label style={{ fontSize: '12px' }}>Background Opacity: {Math.round(bgOpacity * 100)}%</label>
            <input 
              type="range" min="0" max="1" step="0.05"
              value={bgOpacity} 
              onChange={(e) => setBgOpacity(parseFloat(e.target.value))}
              style={{ width: '100%' }}
            />
          </div>
        )}

        {activeLayer && (
          <div style={{ marginBottom: '20px' }}>
            <h3 style={{ fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '10px', paddingTop: '10px', borderTop: '1px solid var(--border-color)' }}>Appearance</h3>
            <div className="input-group">
              <label>Opacity: {Math.round((activeLayer.opacity !== undefined ? activeLayer.opacity : 1) * 100)}%</label>
              <input 
                type="range" min="0" max="1" step="0.05"
                value={activeLayer.opacity !== undefined ? activeLayer.opacity : 1} 
                onChange={(e) => updateLayer(activeLayer.id, { opacity: parseFloat(e.target.value) })}
                style={{ width: '100%' }}
              />
            </div>
            <div className="input-group">
              <label>Frame Width: {activeLayer.borderWidth || 0}px</label>
              <input 
                type="range" min="0" max="50" step="1"
                value={activeLayer.borderWidth || 0} 
                onChange={(e) => updateLayer(activeLayer.id, { borderWidth: parseInt(e.target.value) })}
                style={{ width: '100%' }}
              />
            </div>
            {(activeLayer.borderWidth || 0) > 0 && (
              <div className="input-group">
                <label>Frame Color</label>
                <input 
                  type="color" 
                  value={activeLayer.borderColor || '#000000'} 
                  onChange={(e) => updateLayer(activeLayer.id, { borderColor: e.target.value })}
                  style={{ padding: '0', height: '40px', cursor: 'pointer' }}
                />
              </div>
            )}
          </div>
        )}

        {activeLayer && activeLayer.type === 'shape' && (
          <div>
            <h3 style={{ fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '10px', paddingTop: '10px', borderTop: '1px solid var(--border-color)' }}>Edit Shape</h3>
            <div className="input-group">
              <label>Shape</label>
              <select 
                value={activeLayer.shape} 
                onChange={(e) => updateLayer(activeLayer.id, { shape: e.target.value })}
              >
                <option value="circle">Circle</option>
                <option value="square">Square</option>
                <option value="rounded-rectangle">Rounded Rectangle</option>
                <option value="oval">Oval</option>
                <option value="arch">Arch</option>
              </select>
            </div>
            <div className="input-group">
              <label>Fill Color</label>
              <input 
                type="color" 
                value={activeLayer.color || '#4A6572'} 
                onChange={(e) => updateLayer(activeLayer.id, { color: e.target.value })}
                style={{ padding: '0', height: '40px', cursor: 'pointer' }}
              />
            </div>
          </div>
        )}

        {activeLayer && activeLayer.type === 'text' && (
          <div>
            <h3 style={{ fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '10px', paddingTop: '10px', borderTop: '1px solid var(--border-color)' }}>Edit Text</h3>
            <div className="input-group">
              <label>Content</label>
              <input 
                value={activeLayer.content} 
                onChange={(e) => updateLayer(activeLayer.id, { content: e.target.value })}
              />
            </div>
            <div className="input-group">
              <label>Font Family</label>
              <select 
                value={activeLayer.fontFamily || 'Inter'} 
                onChange={(e) => updateLayer(activeLayer.id, { fontFamily: e.target.value })}
              >
                <option value="Inter">Inter</option>
                <option value="Roboto">Roboto</option>
                <option value="Playfair Display">Playfair Display</option>
                <option value="Great Vibes">Great Vibes</option>
                <option value="Georgia">Georgia</option>
              </select>
            </div>
            <div className="input-group">
              <label>Font Size</label>
              <input 
                type="number" 
                value={activeLayer.fontSize} 
                onChange={(e) => updateLayer(activeLayer.id, { fontSize: Number(e.target.value) })}
              />
            </div>
            <div className="input-group">
              <label>Color</label>
              <input 
                type="color" 
                value={activeLayer.color} 
                onChange={(e) => updateLayer(activeLayer.id, { color: e.target.value })}
                style={{ padding: '0', height: '40px', cursor: 'pointer' }}
              />
            </div>
            <div className="input-group">
              <label>Style</label>
              <div style={{ display: 'flex', gap: '5px' }}>
                <button 
                  className="btn" 
                  style={{ flex: 1, padding: '5px', fontWeight: 'bold', background: activeLayer.fontWeight === 'bold' ? 'var(--primary-color)' : 'var(--surface-color)', color: activeLayer.fontWeight === 'bold' ? 'white' : 'var(--text-primary)' }}
                  onClick={() => updateLayer(activeLayer.id, { fontWeight: activeLayer.fontWeight === 'bold' ? 'normal' : 'bold' })}
                >B</button>
                <button 
                  className="btn" 
                  style={{ flex: 1, padding: '5px', fontStyle: 'italic', background: activeLayer.fontStyle === 'italic' ? 'var(--primary-color)' : 'var(--surface-color)', color: activeLayer.fontStyle === 'italic' ? 'white' : 'var(--text-primary)' }}
                  onClick={() => updateLayer(activeLayer.id, { fontStyle: activeLayer.fontStyle === 'italic' ? 'normal' : 'italic' })}
                >I</button>
                <button 
                  className="btn" 
                  style={{ flex: 1, padding: '5px', textDecoration: 'underline', background: activeLayer.textDecoration === 'underline' ? 'var(--primary-color)' : 'var(--surface-color)', color: activeLayer.textDecoration === 'underline' ? 'white' : 'var(--text-primary)' }}
                  onClick={() => updateLayer(activeLayer.id, { textDecoration: activeLayer.textDecoration === 'underline' ? 'none' : 'underline' })}
                >U</button>
              </div>
            </div>
          </div>
        )}

        {activeLayer && activeLayer.type === 'image_frame' && (
          <div>
            <h3 style={{ fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '10px', paddingTop: '10px', borderTop: '1px solid var(--border-color)' }}>Edit Frame</h3>
            <div className="input-group">
              <label>Shape</label>
              <select 
                value={activeLayer.shape} 
                onChange={(e) => updateLayer(activeLayer.id, { shape: e.target.value })}
              >
                <option value="circle">Circle</option>
                <option value="square">Square</option>
                <option value="rounded-rectangle">Rounded Rectangle</option>
                <option value="oval">Oval</option>
                <option value="arch">Arch</option>
              </select>
            </div>
            <div className="input-group">
              <label>Upload Photo</label>
              <input 
                type="file" 
                accept="image/*"
                onChange={(e) => {
                  if (e.target.files && e.target.files[0]) {
                    const url = URL.createObjectURL(e.target.files[0]);
                    updateLayer(activeLayer.id, { src: url });
                  }
                }}
                style={{ fontSize: '12px' }}
              />
            </div>
          </div>
        )}
      </aside>
    </div>
  );
}
