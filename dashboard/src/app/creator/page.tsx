'use client';
import { useState, useRef, Suspense, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { Rnd } from 'react-rnd';
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd';
import { 
  Eye, 
  EyeOff, 
  Trash2, 
  GripVertical, 
  Type, 
  Image as ImageIcon, 
  Square, 
  FileImage, 
  Wallpaper,
  Layers,
  ChevronLeft,
  Flower2
} from 'lucide-react';
import { useSearchParams, useRouter } from 'next/navigation';

const GOOGLE_FONTS_LIBRARY = [
  'Inter',
  'Playfair Display',
  'Roboto',
  'Georgia',
  'Cinzel',
  'Lora',
  'Cormorant Garamond',
  'EB Garamond',
  'Merriweather',
  'Great Vibes',
  'Alex Brush',
  'Pinyon Script',
  'Parisienne',
  'Playball',
  'Dancing Script',
  'Montserrat',
  'Lato',
  'Open Sans',
  'Raleway',
  'Bodoni Moda',
  'Cinzel Decorative',
  'Cormorant Infant',
  'Crimson Text',
  'Marcellus',
  'Montserrat Alternates',
  'Cardo',
  'Italiana',
  'Prata',
  'Allura',
  'Sacramento',
  'WindSong',
  'Reenie Beanie',
  'Satisfy',
  'Petit Formal Script',
  'Rouge Script'
];

export default function CreatorStudioPage() {
  return (
    <Suspense fallback={<div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', color: 'var(--accent-color)', backgroundColor: 'var(--bg-color)', fontFamily: 'var(--font-interface)' }}>Loading Studio...</div>}>
      <CreatorStudio />
    </Suspense>
  );
}

interface Layer {
  id: string;
  type: string;
  content?: string;
  fontFamily?: string;
  fontSize?: number;
  color?: string;
  fontWeight?: string;
  fontStyle?: string;
  textDecoration?: string;
  x: number;
  y: number;
  width: number;
  height: number;
  visible: boolean;
  src?: string | null;
  shape?: string;
  opacity?: number;
  borderWidth?: number;
  borderColor?: string;
  rotation?: number;
  borderRadius?: number;
  locked?: boolean;
  textBackgroundColor?: string;
  textPadding?: number;
  shadowColor?: string;
  shadowBlur?: number;
  shadowOffsetX?: number;
  shadowOffsetY?: number;
  outlineWidth?: number;
  outlineColor?: string;
  lineHeight?: number;
  letterSpacing?: number;
  textTransform?: string;
  imageScale?: number;
  imageOffsetX?: number;
  imageOffsetY?: number;
  mixBlendMode?: string;
  children?: Layer[];
  isCustomWidth?: boolean;
  hasShadow?: boolean;
  glowColor?: string;
  glowBlur?: number;
  echoColor?: string;
  echoOffsetX?: number;
  echoOffsetY?: number;
  neonColor?: string;
  neonIntensity?: number;
  curveIntensity?: number;
  frameStyle?: string;
  alignment?: string;
}

interface HistoryState {
  layers: Layer[];
  background: string | null;
  bgOpacity: number;
  backgroundType: 'color' | 'image';
  solidColor: string;
}

const apiBase = '';

function CreatorStudio() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentTemplateIdRef = useRef<string | null>(searchParams.get('id'));
  const [currentTemplateId, setCurrentTemplateId] = useState<string | null>(searchParams.get('id'));
  const [autoSaveEnabled, setAutoSaveEnabled] = useState(true);
  const [lastSaved, setLastSaved] = useState<Date | null>(null);
  const [canvasWidth, setCanvasWidth] = useState(1080);
  const [canvasHeight, setCanvasHeight] = useState(1920);

  // Initialize canvas size from search params if present
  useEffect(() => {
    const w = searchParams.get('width');
    const h = searchParams.get('height');
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (w) setCanvasWidth(Number(w));
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (h) setCanvasHeight(Number(h));
  }, [searchParams]);

  const width = canvasWidth.toString();
  const height = canvasHeight.toString();

  // Calculate scaled canvas size for the preview area
  const previewHeight = 650;
  const scale = previewHeight / canvasHeight;
  const previewWidth = canvasWidth * scale;

  const [layers, setLayers] = useState<Layer[]>([]);
  
  const [templateName, setTemplateName] = useState('Custom Template');
  const [background, setBackground] = useState<string | null>(null);
  const [bgOpacity, setBgOpacity] = useState(1);
  const [backgroundType, setBackgroundType] = useState<'color' | 'image'>('color');
  const [solidColor, setSolidColor] = useState('#FFFFFF');
  
  // Active Shape Layer States
  const [shapeFillType, setShapeFillType] = useState<'solid' | 'gradient'>('solid');
  const [shapeSolidColor, setShapeSolidColor] = useState('#C5A880');
  const [shapeColor1, setShapeColor1] = useState('#1E252B');
  const [shapeColor2, setShapeColor2] = useState('#C5A880');
  const [shapeAngle, setShapeAngle] = useState(135);

  const [activeLayerId, setActiveLayerId] = useState<string | null>(null);
  const [selectedLayerIds, setSelectedLayerIds] = useState<string[]>([]);
  const [contextMenu, setContextMenu] = useState<{ visible: boolean; x: number; y: number; layerId: string | null }>({ visible: false, x: 0, y: 0, layerId: null });
  const [selectionBox, setSelectionBox] = useState<{ startX: number; startY: number; currentX: number; currentY: number } | null>(null);
  const [snapToGrid, setSnapToGrid] = useState(true);
  const [rightSidebarTab, setRightSidebarTab] = useState<'elements' | 'verses' | 'graphics' | 'flowers'>('elements');
  const [elementSubPanel, setElementSubPanel] = useState<'main' | 'shape_selector' | 'frame_selector'>('main');
  const [activeTextEffect, setActiveTextEffect] = useState<string | null>(null);
  const [isDraggingCustom, setIsDraggingCustom] = useState(false);

  const [showFontDropdown, setShowFontDropdown] = useState(false);
  const [shapeGradientType, setShapeGradientType] = useState<'two-color' | 'transparent'>('two-color');

  const selectLayer = useCallback((id: string | null) => {
    setActiveLayerId(id);
    setSelectedLayerIds(id ? [id] : []);
    if (id) {
      const layer = layers.find(l => l.id === id);
      if (layer && layer.type === 'shape') {
        const colorVal = layer.color || '#C5A880';
        if (colorVal.startsWith('linear-gradient')) {
          setShapeFillType('gradient');
          const match = colorVal.match(/linear-gradient\((\d+)deg,\s*(#[a-fA-F0-9]{6}),\s*(#[a-fA-F0-9]{6}|transparent)\)/);
          if (match) {
            setShapeAngle(parseInt(match[1]));
            setShapeColor1(match[2]);
            if (match[3] === 'transparent') {
              setShapeGradientType('transparent');
              setShapeColor2('#000000');
            } else {
              setShapeGradientType('two-color');
              setShapeColor2(match[3]);
            }
          }
        } else {
          setShapeFillType('solid');
          setShapeSolidColor(colorVal);
        }
      }
    }
  }, [layers]);

  const handleLayerSelectToggle = useCallback((id: string | null, isShift: boolean) => {
    if (!id) {
      setActiveLayerId(null);
      setSelectedLayerIds([]);
      return;
    }
    if (isShift) {
      setSelectedLayerIds(prev => {
        const next = prev.includes(id) 
          ? prev.filter(item => item !== id) 
          : [...prev, id];
        setActiveLayerId(next[next.length - 1] || null);
        return next;
      });
    } else {
      selectLayer(id);
    }
  }, [selectLayer]);

  const [editingLayerId, setEditingLayerId] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isNearMargin, setIsNearMargin] = useState(false);
  
  const bgInputRef = useRef<HTMLInputElement>(null);
  const overlayInputRef = useRef<HTMLInputElement>(null);

  const [history, setHistory] = useState<HistoryState[]>([]);
  const historyIndexRef = useRef(-1);
  const [clipboard, setClipboard] = useState<Layer | null>(null);

  // Load Google Fonts Library on mount
  useEffect(() => {
    const fontParams = GOOGLE_FONTS_LIBRARY.map(font => `family=${font.replace(/\s+/g, '+')}`).join('&');
    const href = `https://fonts.googleapis.com/css2?${fontParams}&display=swap`;
    
    const id = 'google-fonts-library';
    if (!document.getElementById(id)) {
      const link = document.createElement('link');
      link.id = id;
      link.rel = 'stylesheet';
      link.href = href;
      document.head.appendChild(link);
    }
  }, []);

  // Dismiss context menu on click
  useEffect(() => {
    const handleGlobalClick = () => {
      setContextMenu(prev => prev.visible ? { ...prev, visible: false } : prev);
    };
    window.addEventListener('click', handleGlobalClick);
    return () => window.removeEventListener('click', handleGlobalClick);
  }, []);

  // Window-level mouse listeners for Drag-to-Select Marquee
  useEffect(() => {
    if (!selectionBox) return;

    const handleMouseMove = (e: MouseEvent) => {
      setSelectionBox(prev => {
        if (!prev) return null;
        return {
          ...prev,
          currentX: e.clientX,
          currentY: e.clientY
        };
      });
    };

    const handleMouseUp = (e: MouseEvent) => {
      const canvasElement = document.querySelector('.canvas-area');
      if (canvasElement && selectionBox) {
        // Calculate the selection box bounding rect in absolute window coordinates
        const x1 = Math.min(selectionBox.startX, selectionBox.currentX);
        const y1 = Math.min(selectionBox.startY, selectionBox.currentY);
        const x2 = Math.max(selectionBox.startX, selectionBox.currentX);
        const y2 = Math.max(selectionBox.startY, selectionBox.currentY);

        // Calculate overlap with each layer
        const newlySelectedIds: string[] = [];
        layers.forEach(layer => {
          const parent = document.getElementById(`parent-container-${layer.id}`);
          if (parent) {
            const rect = parent.getBoundingClientRect();
            // Check intersection between layer rect and selection box
            const intersects = !(rect.right < x1 || rect.left > x2 || rect.bottom < y1 || rect.top > y2);
            if (intersects) {
              newlySelectedIds.push(layer.id);
            }
          }
        });

        if (newlySelectedIds.length > 0) {
          setSelectedLayerIds(prev => {
            if (e.shiftKey) {
              const unique = Array.from(new Set([...prev, ...newlySelectedIds]));
              setActiveLayerId(unique[unique.length - 1] || null);
              return unique;
            } else {
              setActiveLayerId(newlySelectedIds[0]);
              return newlySelectedIds;
            }
          });
        }
      }
      setSelectionBox(null);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [selectionBox, layers, scale]);

  // Debounced History Save
  useEffect(() => {
    const timer = setTimeout(() => {
      setHistory((prev) => {
        const currentIndex = historyIndexRef.current;
        const lastState = prev[currentIndex];
        const currentState = { 
          layers, 
          background, 
          bgOpacity,
          backgroundType,
          solidColor
        };
        
        if (lastState && JSON.stringify(lastState) === JSON.stringify(currentState)) {
           return prev;
        }
        
        const newHistory = prev.slice(0, currentIndex + 1);
        newHistory.push(currentState);
        historyIndexRef.current = newHistory.length - 1;
        return newHistory;
      });
    }, 400);
    return () => clearTimeout(timer);
  }, [layers, background, bgOpacity, backgroundType, solidColor]);

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
            selectLayer(null);
          }
        }
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'v') {
         if (clipboard) {
            const newLayer = { ...clipboard, id: Date.now().toString(), x: clipboard.x + 20, y: clipboard.y + 20 };
             setLayers([...layers, newLayer]);
             selectLayer(newLayer.id);
             setClipboard(newLayer);
         }
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') {
         if (e.shiftKey) {
            if (historyIndexRef.current < history.length - 1) {
                const newIndex = historyIndexRef.current + 1;
                const nextState = history[newIndex];
                historyIndexRef.current = newIndex;
                setLayers(nextState.layers);
                 setBackground(nextState.background);
                 setBgOpacity(nextState.bgOpacity);
                 setBackgroundType(nextState.backgroundType);
                 setSolidColor(nextState.solidColor);
             }
          } else {
             if (historyIndexRef.current > 0) {
                 const newIndex = historyIndexRef.current - 1;
                 const prevState = history[newIndex];
                 historyIndexRef.current = newIndex;
                 setLayers(prevState.layers);
                 setBackground(prevState.background);
                 setBgOpacity(prevState.bgOpacity);
                 setBackgroundType(prevState.backgroundType);
                 setSolidColor(prevState.solidColor);
             }
          }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [layers, activeLayerId, clipboard, history, selectLayer]);

  useEffect(() => {
    const initialId = searchParams.get('id');
    if (!initialId) return;

    fetch(`${apiBase}/api/templates/${initialId}`, { cache: 'no-store' })
      .then((res) => {
        if (res.ok) return res.json();
        return null;
      })
      .then((data) => {
        if (!data) {
          alert('Template not found or deleted. Starting a new template.');
          window.location.href = '/creator';
          return;
        }
        
        if (data.title) setTemplateName(data.title);

        if (data.width) setCanvasWidth(data.width);
        if (data.height) setCanvasHeight(data.height);
        if (data.background) {
          const bg = data.background;
          const bgType = bg.type || 'color';
          setBackgroundType(bgType);
          
          if (bgType === 'image') {
            setBackground(bg.value || null);
          } else {
            setBackgroundType('color');
            if (bgType === 'gradient') {
              const gradientStr = bg.value || '';
              const match = gradientStr.match(/linear-gradient\((\d+)deg,\s*(#[a-fA-F0-9]{6}),\s*(#[a-fA-F0-9]{6})\)/);
              setSolidColor(match ? match[2] : '#FFFFFF');
            } else {
              setSolidColor(bg.value || '#FFFFFF');
            }
          }
        }
        
        const w = data.width || 1080;
        const h = data.height || 1080;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const loadedText = (data.textLayers || []).map((l: any) => ({
          id: l.id,
          type: 'text',
          content: l.content,
          fontFamily: l.fontFamily,
          fontSize: l.fontSize * w,
          color: l.color,
          alignment: l.alignment,
          x: l.x * w,
          y: l.y * h,
          width: l.width ? l.width * w : undefined,
          height: l.height ? l.height * h : undefined,
          fontWeight: l.fontWeight || 'normal',
          fontStyle: l.fontStyle || 'normal',
          textDecoration: l.textDecoration || 'none',
          opacity: l.opacity !== undefined ? l.opacity : 1,
          rotation: l.rotation || 0,
          visible: true,
          zIndex: l.zIndex !== undefined ? l.zIndex : 0
        }));

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const loadedImage = (data.imageLayers || []).map((l: any) => ({
          id: l.id,
          type: l.type === 'frame' ? 'image_frame' : 'image',
          src: l.url,
          shape: l.type === 'frame' 
            ? (l.maskShape === 'circle' ? 'circle' : l.maskShape === 'rounded_rect' ? 'rounded-rectangle' : 'square') 
            : undefined,
          x: l.x * w,
          y: l.y * h,
          width: l.width * w,
          height: l.height * h,
          rotation: l.rotation || 0,
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: (l.borderWidth || 0) * w,
          borderColor: l.borderColor || '#000000',
          mixBlendMode: l.mixBlendMode || 'normal',
          visible: true,
          zIndex: l.zIndex !== undefined ? l.zIndex : 0
        }));

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const loadedShape = (data.shapeLayers || []).map((l: any) => ({
          id: l.id,
          type: 'shape',
          shape: l.shape || 'square',
          color: l.color || '#4A6572',
          x: l.x * w,
          y: l.y * h,
          width: l.width * w,
          height: l.height * h,
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: (l.borderWidth || 0) * w,
          borderColor: l.borderColor || '#000000',
          rotation: l.rotation || 0,
          visible: true,
          zIndex: l.zIndex !== undefined ? l.zIndex : 0
        }));

        const allLayers = [...loadedText, ...loadedImage, ...loadedShape];
        allLayers.sort((a, b) => a.zIndex - b.zIndex);
        setLayers(allLayers);
      })
      .catch((err) => {
        console.error(err);
        alert('Failed to load template from database.');
      });
  }, [searchParams]);

  const activeLayer = layers.find(l => l.id === activeLayerId);



  const handleShapeSolidColorChange = (color: string) => {
    setShapeSolidColor(color);
    if (activeLayerId) {
      updateLayer(activeLayerId, { color });
    }
  };

  const handleShapeGradientChange = (color1: string, color2: string, angle: number, gradType: 'two-color' | 'transparent' = shapeGradientType) => {
    setShapeColor1(color1);
    setShapeColor2(color2);
    setShapeAngle(angle);
    setShapeGradientType(gradType);
    if (activeLayerId) {
      const finalC2 = gradType === 'transparent' ? 'transparent' : color2;
      const gradientStr = `linear-gradient(${angle}deg, ${color1}, ${finalC2})`;
      updateLayer(activeLayerId, { color: gradientStr });
    }
  };

  const updateLayer = (id: string, updates: Partial<Layer>) => {
    setLayers(layers.map(l => l.id === id ? { ...l, ...updates } : l));
  };

  const handleRotationStart = (e: React.MouseEvent, layer: Layer) => {
    e.preventDefault();
    e.stopPropagation();

    const element = document.getElementById(`rnd-container-${layer.id}`);
    if (!element) return;

    // Get unrotated dimensions from DOM
    const w = element.offsetWidth / scale;
    const h = element.offsetHeight / scale;

    const rect = element.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;

    const handleMouseMove = (moveEvent: MouseEvent) => {
      const dx = moveEvent.clientX - centerX;
      const dy = moveEvent.clientY - centerY;
      let angle = Math.atan2(dy, dx) * (180 / Math.PI);
      
      // Handle is at the bottom, so drag down is 0 degrees
      angle = angle - 90;
      if (angle < 0) angle += 360;
      
      const newRotation = Math.round(angle);
      const prevRotation = layer.rotation || 0;
      
      // Calculate origin shift to keep center pivot visually stable under transformOrigin 0 0
      const rad1 = (prevRotation * Math.PI) / 180;
      const rad2 = (newRotation * Math.PI) / 180;
      
      const shiftX = (w / 2) * (Math.cos(rad1) - Math.cos(rad2)) - (h / 2) * (Math.sin(rad1) - Math.sin(rad2));
      const shiftY = (w / 2) * (Math.sin(rad1) - Math.sin(rad2)) + (h / 2) * (Math.cos(rad1) - Math.cos(rad2));
      
      updateLayer(layer.id, { 
        rotation: newRotation,
        x: layer.x + shiftX,
        y: layer.y + shiftY
      });
    };

    const handleMouseUp = () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  };

  const rotateLayerAroundCenter = (layerId: string, newRotation: number) => {
    const layer = layers.find(l => l.id === layerId);
    if (!layer) return;

    const element = document.getElementById(`rnd-container-${layer.id}`);
    const w = element ? element.offsetWidth / scale : (layer.width || 100);
    const h = element ? element.offsetHeight / scale : (layer.height || 100);

    const prevRotation = layer.rotation || 0;
    const rad1 = (prevRotation * Math.PI) / 180;
    const rad2 = (newRotation * Math.PI) / 180;

    const shiftX = (w / 2) * (Math.cos(rad1) - Math.cos(rad2)) - (h / 2) * (Math.sin(rad1) - Math.sin(rad2));
    const shiftY = (w / 2) * (Math.sin(rad1) - Math.sin(rad2)) + (h / 2) * (Math.cos(rad1) - Math.cos(rad2));

    updateLayer(layer.id, {
      rotation: newRotation,
      x: layer.x + shiftX,
      y: layer.y + shiftY
    });
  };

  const handleDragStart = (e: React.MouseEvent, layer: Layer) => {
    if (layer.locked) return;
    if (editingLayerId === layer.id) return;
    if (e.button !== 0) return; // Only handle left clicks
    e.stopPropagation();

    const parent = document.getElementById(`parent-container-${layer.id}`);
    if (!parent) return;

    const startX = e.clientX;
    const startY = e.clientY;

    const initialLeft = parseFloat(parent.style.left) || (layer.x * scale);
    const initialTop = parseFloat(parent.style.top) || (layer.y * scale);

    let currentLeft = initialLeft;
    let currentTop = initialTop;
    let hasDragged = false;
    const isShiftPressed = e.shiftKey;

    const handleMouseMove = (moveEvent: MouseEvent) => {
      let dx = moveEvent.clientX - startX;
      let dy = moveEvent.clientY - startY;

      // Threshold check
      if (!hasDragged) {
        if (Math.abs(dx) > 4 || Math.abs(dy) > 4) {
          hasDragged = true;
          setIsDraggingCustom(true);
          if (!selectedLayerIds.includes(layer.id)) {
            handleLayerSelectToggle(layer.id, isShiftPressed);
          }
        } else {
          return;
        }
      }

      moveEvent.preventDefault();

      // Implement snap to grid (10px increments)
      if (snapToGrid) {
        const gridStep = 10 * scale;
        dx = Math.round(dx / gridStep) * gridStep;
        dy = Math.round(dy / gridStep) * gridStep;
      }

      currentLeft = initialLeft + dx;
      currentTop = initialTop + dy;

      parent.style.left = `${currentLeft}px`;
      parent.style.top = `${currentTop}px`;
    };

    const handleMouseUp = () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);

      if (!hasDragged) {
        handleLayerSelectToggle(layer.id, isShiftPressed);
      } else {
        setIsDraggingCustom(false);
        updateLayer(layer.id, {
          x: currentLeft / scale,
          y: currentTop / scale
        });
      }
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  };

  const renderFrameOverlay = (frameStyle: string | undefined, shape: string | undefined) => {
    if (!frameStyle || frameStyle === 'simple') return null;

    const borderRadius = shape === 'circle' ? '50%' : (shape === 'rounded-rectangle' ? '20px' : '0');

    if (frameStyle === 'gold') {
      return (
        <div style={{
          width: '100%',
          height: '100%',
          border: '4px double #D4AF37',
          borderRadius,
          boxSizing: 'border-box',
          position: 'absolute',
          top: 0, left: 0, right: 0, bottom: 0,
          pointerEvents: 'none',
          zIndex: 5
        }} />
      );
    }

    if (frameStyle === 'mourning') {
      return (
        <div style={{
          width: '100%',
          height: '100%',
          border: '4px solid #1E252B',
          borderRadius,
          boxSizing: 'border-box',
          position: 'absolute',
          top: 0, left: 0, right: 0, bottom: 0,
          pointerEvents: 'none',
          zIndex: 5,
          overflow: 'hidden'
        }}>
          {/* Black corner ribbon */}
          <div style={{
            position: 'absolute',
            top: '8px',
            right: '-28px',
            width: '80px',
            height: '14px',
            background: '#1E252B',
            transform: 'rotate(45deg)',
            zIndex: 10
          }} />
        </div>
      );
    }

    if (frameStyle === 'rosary' && shape === 'circle') {
      return (
        <div style={{
          width: '100%',
          height: '100%',
          border: '2px solid #C5A880',
          borderRadius: '50%',
          boxSizing: 'border-box',
          position: 'absolute',
          top: 0, left: 0, right: 0, bottom: 0,
          pointerEvents: 'none',
          zIndex: 5
        }}>
          {/* Decorative double circle beads */}
          <div style={{
            position: 'absolute',
            top: '-4px', left: '-4px', right: '-4px', bottom: '-4px',
            border: '2px dotted #C5A880',
            borderRadius: '50%'
          }} />
        </div>
      );
    }

    if (frameStyle === 'floral') {
      return (
        <div style={{
          width: '100%',
          height: '100%',
          border: '1px solid #C5A880',
          borderRadius,
          boxSizing: 'border-box',
          position: 'absolute',
          top: 0, left: 0, right: 0, bottom: 0,
          pointerEvents: 'none',
          zIndex: 5
        }}>
          {/* Four corner star beads */}
          <div style={{ position: 'absolute', top: '4px', left: '4px', color: '#C5A880', fontSize: '10px', fontWeight: 'bold' }}>✦</div>
          <div style={{ position: 'absolute', top: '4px', right: '4px', color: '#C5A880', fontSize: '10px', fontWeight: 'bold' }}>✦</div>
          <div style={{ position: 'absolute', bottom: '4px', left: '4px', color: '#C5A880', fontSize: '10px', fontWeight: 'bold' }}>✦</div>
          <div style={{ position: 'absolute', bottom: '4px', right: '4px', color: '#C5A880', fontSize: '10px', fontWeight: 'bold' }}>✦</div>
        </div>
      );
    }

    if (frameStyle === 'silver') {
      return (
        <div style={{
          width: '100%',
          height: '100%',
          border: '4px double #94A3B8',
          borderRadius,
          boxSizing: 'border-box',
          position: 'absolute',
          top: 0, left: 0, right: 0, bottom: 0,
          pointerEvents: 'none',
          zIndex: 5
        }} />
      );
    }

    return null;
  };

  const alignActiveLayer = (alignment: 'left' | 'center' | 'right' | 'top' | 'middle' | 'bottom') => {
    if (!activeLayerId) return;
    const active = layers.find(l => l.id === activeLayerId);
    if (!active) return;

    const canvasWidth = Number(width);
    const canvasHeight = Number(height);
    const layerWidth = active.width || 400;
    const layerHeight = active.height || 100;

    let newX = active.x;
    let newY = active.y;

    switch (alignment) {
      case 'left':
        newX = 0;
        break;
      case 'center':
        newX = (canvasWidth - layerWidth) / 2;
        break;
      case 'right':
        newX = canvasWidth - layerWidth;
        break;
      case 'top':
        newY = 0;
        break;
      case 'middle':
        newY = (canvasHeight - layerHeight) / 2;
        break;
      case 'bottom':
        newY = canvasHeight - layerHeight;
        break;
    }

    updateLayer(activeLayerId, { x: newX, y: newY });
  };

  const handleDragEnd = (result: DropResult) => {
    if (!result.destination) return;
    
    const items = [...layers].reverse();
    const [reorderedItem] = items.splice(result.source.index, 1);
    items.splice(result.destination.index, 0, reorderedItem);
    
    setLayers(items.reverse());
  };

  const deleteLayer = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setLayers(layers.filter(l => l.id !== id));
    if (activeLayerId === id) selectLayer(null);
  };

  const groupSelectedLayers = useCallback(() => {
    if (selectedLayerIds.length <= 1) return;
    
    const layersToGroup = layers.filter(l => selectedLayerIds.includes(l.id));
    if (layersToGroup.length <= 1) return;

    const minX = Math.min(...layersToGroup.map(l => l.x));
    const minY = Math.min(...layersToGroup.map(l => l.y));
    const maxX = Math.max(...layersToGroup.map(l => l.x + (l.width || 100)));
    const maxY = Math.max(...layersToGroup.map(l => l.y + (l.height || 100)));
    
    const groupWidth = maxX - minX;
    const groupHeight = maxY - minY;

    const children = layersToGroup.map(l => ({
      ...l,
      x: l.x - minX,
      y: l.y - minY
    }));

    const newGroupId = `group-${Date.now()}`;
    const newGroupLayer: Layer = {
      id: newGroupId,
      type: 'group',
      x: minX,
      y: minY,
      width: groupWidth,
      height: groupHeight,
      visible: true,
      rotation: 0,
      children
    };

    const remainingLayers = layers.filter(l => !selectedLayerIds.includes(l.id));
    const firstIndex = layers.findIndex(l => selectedLayerIds.includes(l.id));
    const newLayers = [...remainingLayers];
    newLayers.splice(firstIndex >= 0 ? firstIndex : newLayers.length, 0, newGroupLayer);

    setLayers(newLayers);
    selectLayer(newGroupId);
  }, [layers, selectedLayerIds, selectLayer]);

  const ungroupSelectedLayers = useCallback(() => {
    if (selectedLayerIds.length !== 1) return;
    const targetGroupId = selectedLayerIds[0];
    const groupLayer = layers.find(l => l.id === targetGroupId);
    if (!groupLayer || groupLayer.type !== 'group' || !groupLayer.children) return;

    const restoredLayers = groupLayer.children.map(child => ({
      ...child,
      x: groupLayer.x + child.x,
      y: groupLayer.y + child.y,
      rotation: (groupLayer.rotation || 0) + (child.rotation || 0)
    }));

    const groupIndex = layers.findIndex(l => l.id === targetGroupId);
    const newLayers = layers.filter(l => l.id !== targetGroupId);
    newLayers.splice(groupIndex >= 0 ? groupIndex : newLayers.length, 0, ...restoredLayers);

    setLayers(newLayers);
    setSelectedLayerIds(restoredLayers.map(l => l.id));
    setActiveLayerId(restoredLayers[0]?.id || null);
  }, [layers, selectedLayerIds]);

  const toggleVisibility = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setLayers(layers.map(l => l.id === id ? { ...l, visible: !l.visible } : l));
  };

  const uploadFile = async (file: File): Promise<string> => {
    const formData = new FormData();
    formData.append('file', file);
    const response = await fetch(`${apiBase}/api/upload`, {
      method: 'POST',
      body: formData
    });
    if (!response.ok) {
      throw new Error('Failed to upload file');
    }
    const data = await response.json();
    return `${apiBase}${data.url}`;
  };

  const handleBgUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      try {
        const file = e.target.files[0];
        const localUrl = URL.createObjectURL(file);
        setBackground(localUrl);
        
        const serverUrl = await uploadFile(file);
        setBackground(serverUrl);
      } catch (err) {
        console.error(err);
        alert('Failed to upload background image.');
      }
    }
  };

  const handleSave = async (isAutoSave = false) => {
    const w = canvasWidth;
    const h = canvasHeight;
    // Collect text layers
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const textLayers: any[] = [];
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const imageLayers: any[] = [];
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const shapeLayers: any[] = [];
    
    layers.forEach((l, idx) => {
      if (l.type === 'text') {
        textLayers.push({
          id: l.id,
          content: l.content || 'Text',
          fontFamily: l.fontFamily || 'Inter',
          fontSize: (l.fontSize || 16) / w,
          color: l.color || '#2E3338',
          alignment: l.alignment || 'center',
          fontWeight: l.fontWeight || 'normal',
          fontStyle: l.fontStyle || 'normal',
          textDecoration: l.textDecoration || 'none',
          x: l.x / w,
          y: l.y / h,
          width: l.width ? l.width / w : undefined,
          height: l.height ? l.height / h : undefined,
          rotation: l.rotation || 0,
          hasShadow: l.hasShadow || false,
          shadowColor: l.shadowColor || 'rgba(0,0,0,0.5)',
          shadowBlur: (l.shadowBlur || 0) / w,
          shadowOffsetX: (l.shadowOffsetX || 0) / w,
          shadowOffsetY: (l.shadowOffsetY || 0) / h,
          textBackgroundColor: l.textBackgroundColor || '',
          outlineWidth: (l.outlineWidth || 0) / w,
          outlineColor: l.outlineColor || '#000000',
          lineHeight: l.lineHeight !== undefined ? l.lineHeight : 1.2,
          letterSpacing: l.letterSpacing || 0,
          textTransform: l.textTransform || 'none',
          zIndex: idx
        });
      } else if (l.type === 'image_frame' || l.type === 'image') {
        imageLayers.push({
          id: l.id,
          type: l.type === 'image_frame' ? 'frame' : 'sticker',
          url: l.src || '',
          maskShape: l.type === 'image_frame' 
            ? (l.shape === 'circle' ? 'circle' : l.shape === 'rounded-rectangle' ? 'rounded_rect' : 'none') 
            : 'none',
          x: l.x / w,
          y: l.y / h,
          width: l.width / w,
          height: l.height / h,
          rotation: l.rotation || 0,
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: (l.borderWidth || 0) / w,
          borderColor: l.borderColor || '#000000',
          mixBlendMode: l.mixBlendMode || 'normal',
          zIndex: idx
        });
      } else if (l.type === 'shape') {
        shapeLayers.push({
          id: l.id,
          shape: l.shape || 'square',
          color: l.color || '#4A6572',
          x: l.x / w,
          y: l.y / h,
          width: l.width / w,
          height: l.height / h,
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: (l.borderWidth || 0) / w,
          borderColor: l.borderColor || '#000000',
          rotation: l.rotation || 0,
          zIndex: idx
        });
      }
    });

    let bgValue = '#FFFFFF';
    if (backgroundType === 'image') {
      bgValue = background || '#FFFFFF';
    } else if (backgroundType === 'color') {
      bgValue = solidColor;
    }

    const payload = {
      title: templateName,

      status: isAutoSave ? 'draft' : 'active',
      width: canvasWidth,
      height: canvasHeight,
      background: {
        type: backgroundType,
        value: bgValue
      },
      textLayers,
      imageLayers,
      shapeLayers,
      thumbnailUrl: backgroundType === 'image' ? background || '' : ''
    };

    try {
      const id = currentTemplateIdRef.current;
      const url = id 
        ? `${apiBase}/api/templates/${id}` 
        : `${apiBase}/api/templates`;
      const method = id ? 'PUT' : 'POST';

      const response = await fetch(url, {
        method: method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      if (response.ok) {
        const data = await response.json();
        if (!id && data._id) {
          currentTemplateIdRef.current = data._id;
          setCurrentTemplateId(data._id);
          window.history.replaceState(null, '', `?id=${data._id}`);
        }
        if (isAutoSave) {
          setLastSaved(new Date());
        } else {
          alert(id ? 'Template Updated successfully!' : 'Template Saved to Database!');
        }
      } else if (!isAutoSave) {
        alert('Failed to save to database.');
      }
    } catch (err) {
      console.error(err);
      if (!isAutoSave) alert('Error saving template.');
    }
  };

  // Auto-save effect
  useEffect(() => {
    if (!autoSaveEnabled) return;
    if (layers.length === 0 && backgroundType === 'color' && solidColor === '#FFFFFF') return;

    const timer = setTimeout(() => {
      handleSave(true);
    }, 5000);

    return () => clearTimeout(timer);
  }, [layers, background, solidColor, bgOpacity, backgroundType, templateName, autoSaveEnabled, canvasWidth, canvasHeight]);

  const getShapeBorderRadius = (layer: Layer | undefined) => {
    if (!layer) return '0';
    const shape = layer.shape;
    if (!shape) return '0';
    if (shape === 'circle' || shape === 'oval') return '50%';
    if (shape === 'arch') return '200px 200px 0 0';
    if (shape === 'rounded-rectangle' || shape === 'square') {
      const radiusVal = layer.borderRadius !== undefined ? layer.borderRadius : (shape === 'rounded-rectangle' ? 20 : 0);
      return `${radiusVal * scale}px`;
    }
    return '0';
  };

  const getLayerIcon = (type: string) => {
    switch (type) {
      case 'text': return <Type size={14} style={{ marginRight: '8px', color: 'var(--text-secondary)' }} />;
      case 'image_frame': return <ImageIcon size={14} style={{ marginRight: '8px', color: 'var(--text-secondary)' }} />;
      case 'image': return <FileImage size={14} style={{ marginRight: '8px', color: 'var(--text-secondary)' }} />;
      default: return <Square size={14} style={{ marginRight: '8px', color: 'var(--text-secondary)' }} />;
    }
  };

  return (
    <div className="creator-layout">
      {/* Left side: Properties & Layers panel */}
      <aside className="properties-sidebar" style={{ borderLeft: 'none', borderRight: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <div style={{ marginBottom: '20px' }}>
          <button onClick={() => router.back()} style={{ color: 'var(--accent-color)', textDecoration: 'none', fontSize: '13px', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '15px', background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}>
            <ChevronLeft size={16} /> Go Back
          </button>
          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
             <input 
               value={templateName} 
               onChange={(e) => setTemplateName(e.target.value)}
               style={{ flex: 1, padding: '8px 12px', fontWeight: 'bold' }}
               placeholder="Template Name"
             />
             <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginRight: '8px' }}>
               <label style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '4px', cursor: 'pointer' }}>
                 <input type="checkbox" checked={autoSaveEnabled} onChange={(e) => setAutoSaveEnabled(e.target.checked)} />
                 Auto-save to Draft
               </label>
               {lastSaved && <span style={{ fontSize: '10px', color: 'var(--text-secondary)' }}>Saved {lastSaved.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>}
             </div>
             <button className="btn btn-primary" onClick={() => handleSave(false)} style={{ padding: '8px 16px', borderRadius: 'var(--radius-sm)' }}>Save</button>
          </div>
          <div style={{ display: 'flex', gap: '8px', marginTop: '10px', alignItems: 'center' }}>
            <div style={{ flex: 1 }}></div>
            <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)', cursor: 'pointer', whiteSpace: 'nowrap' }}>
              <input 
                type="checkbox" 
                checked={snapToGrid} 
                onChange={(e) => setSnapToGrid(e.target.checked)} 
                style={{ width: '16px', height: '16px', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
              />
              Snap Grid
            </label>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
          <Layers size={16} style={{ color: 'var(--text-secondary)' }} />
          <h3 style={{ fontSize: '14px', margin: 0, fontWeight: 'bold', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)' }}>Layers (Drag to reorder)</h3>
        </div>
        
        {/* Drag and Drop Layer List */}
        <div style={{ flex: 1, overflowY: 'auto' }}>
          <DragDropContext onDragEnd={handleDragEnd}>
            <Droppable droppableId="layers">
              {(provided) => (
                <div {...provided.droppableProps} ref={provided.innerRef}>
                  {[...layers].reverse().map((layer, index) => (
                    <Draggable key={layer.id} draggableId={layer.id} index={index}>
                      {(provided) => (
                        <div
                          ref={provided.innerRef}
                          {...provided.draggableProps}
                          className={`layer-item ${selectedLayerIds.includes(layer.id) ? 'active' : ''}`}
                          onClick={(e) => handleLayerSelectToggle(layer.id, e.shiftKey)}
                          style={{ ...provided.draggableProps.style, background: 'var(--surface-color)' }}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', overflow: 'hidden' }}>
                            <span {...provided.dragHandleProps} style={{ marginRight: '8px', color: 'var(--text-muted)', cursor: 'grab' }}>
                              <GripVertical size={14} />
                            </span>
                            {getLayerIcon(layer.type)}
                            <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '120px' }}>
                              {layer.type === 'text' ? layer.content : layer.type === 'shape' ? 'Shape' : 'Image Frame'}
                            </span>
                          </div>
                          <div style={{ display: 'flex', gap: '10px' }}>
                            <span onClick={(e) => { e.stopPropagation(); updateLayer(layer.id, { locked: !layer.locked }); }} style={{ color: layer.locked ? '#EF4444' : 'var(--text-muted)', cursor: 'pointer' }} title={layer.locked ? "Unlock" : "Lock"}>
                              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                                {layer.locked ? (
                                  <><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></>
                                ) : (
                                  <><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 9.9-1"></path></>
                                )}
                              </svg>
                            </span>
                            <span onClick={(e) => toggleVisibility(layer.id, e)} style={{ color: layer.visible ? 'var(--text-secondary)' : 'var(--text-muted)', cursor: 'pointer' }}>
                              {layer.visible ? <Eye size={14} /> : <EyeOff size={14} />}
                            </span>
                            <span onClick={(e) => deleteLayer(layer.id, e)} style={{ color: '#EF4444', cursor: 'pointer' }}>
                              <Trash2 size={14} />
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
          {/* Static Background Layer */}
          <div
            className={`layer-item ${selectedLayerIds.includes('background') ? 'active' : ''}`}
            onClick={(e) => handleLayerSelectToggle('background', e.shiftKey)}
            style={{ background: 'var(--surface-color)', marginTop: '8px' }}
          >
            <div style={{ display: 'flex', alignItems: 'center', overflow: 'hidden' }}>
              <span style={{ marginRight: '8px', color: 'var(--text-muted)', opacity: 0.5 }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                </svg>
              </span>
              <Wallpaper size={14} style={{ marginRight: '8px', color: 'var(--text-secondary)' }} />
              <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '120px' }}>
                Background
              </span>
            </div>
          </div>
        </div>
      </aside>

      {/* Center Canvas Workspace */}
      <main 
        className="canvas-area" 
        onClick={() => { selectLayer(null); setContextMenu(prev => ({ ...prev, visible: false })); }}
        onMouseDown={(e) => {
          if (e.button !== 0) return;
          const target = e.target as HTMLElement;
          if (target.closest('.rnd-container') || target.closest('[id^="parent-container-"]') || target.closest('button')) {
            return;
          }
          e.preventDefault(); // Prevent text selection and default drag actions
          setSelectionBox({
            startX: e.clientX,
            startY: e.clientY,
            currentX: e.clientX,
            currentY: e.clientY
          });
          if (!e.shiftKey) {
            selectLayer(null);
          }
        }}
        onContextMenu={(e) => {
          e.preventDefault();
          selectLayer(null);
          setContextMenu({
            visible: true,
            x: e.clientX,
            y: e.clientY,
            layerId: null
          });
        }}
        style={{
          backgroundColor: '#E2E8F0',
          backgroundImage: 'radial-gradient(#CBD5E1 1.5px, transparent 1.5px)',
          backgroundSize: '24px 24px'
        }}
      >
        <div style={{ position: 'absolute', top: '24px', color: 'var(--text-secondary)', fontSize: '12px', fontWeight: '500', display: 'flex', alignItems: 'center', gap: '6px', background: 'white', padding: '6px 12px', borderRadius: '20px', boxShadow: 'var(--shadow-sm)' }}>
          Canvas Size: <span style={{ fontWeight: 'bold' }}>{width} x {height}</span>
        </div>
        
        <div 
          style={{
            width: previewWidth,
            height: previewHeight,
            background: 'white',
            boxShadow: '0 25px 50px -12px rgba(30, 37, 43, 0.25)',
            position: 'relative',
            overflow: 'hidden',
            borderRadius: '8px',
            transition: 'box-shadow 0.3s'
          }}
          onMouseMove={(e) => {
            const rect = e.currentTarget.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            const marginX = rect.width * 0.05;
            const marginY = rect.height * 0.05;
            const nearEdge = x < marginX || x > rect.width - marginX || y < marginY || y > rect.height - marginY;
            setIsNearMargin(nearEdge);
          }}
          onMouseLeave={() => setIsNearMargin(false)}
        >
          {/* Safe Margin Guide */}
          {(isDragging || isDraggingCustom || isNearMargin) && (
            <div style={{
              position: 'absolute',
              top: '5%', left: '5%', right: '5%', bottom: '5%',
              border: '1px dashed rgba(239, 68, 68, 0.6)',
              pointerEvents: 'none',
              zIndex: 9999
            }} />
          )}
          {/* Background Layer */}
          {backgroundType === 'image' && background && (
            <div style={{
              position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
              background: `url("${background}") center/100% 100% no-repeat`,
              opacity: bgOpacity,
              pointerEvents: 'none'
            }} />
          )}
          {backgroundType === 'color' && (
            <div style={{
              position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
              backgroundColor: solidColor,
              pointerEvents: 'none'
            }} />
          )}
          {[...layers].reverse().map((layer, idx) => {
            if (!layer.visible) return null;
            const isSelected = selectedLayerIds.includes(layer.id);
            const baseZIndex = layers.length - idx;
            const zIndex = baseZIndex; // Removed `1000 +` so selected layers stay in their correct z-index order
            const angleRad = ((layer.rotation || 0) * Math.PI) / 180;
            const cosAngle = Math.cos(angleRad);
            const sinAngle = Math.sin(angleRad);

            return (
              <div
                key={layer.id}
                id={`parent-container-${layer.id}`}
                className={layer.mixBlendMode === 'multiply' ? 'multiply-blend' : ''}
                style={{
                  position: 'absolute',
                  left: layer.x * scale,
                  top: layer.y * scale,
                  width: layer.width * scale,
                  height: layer.type === 'text' ? 'auto' : layer.height * scale,
                  transform: `rotate(${layer.rotation || 0}deg)`,
                  transformOrigin: '0 0',
                  zIndex,
                  pointerEvents: 'none'
                }}
              >
                <Rnd
                  size={{ width: '100%', height: layer.type === 'text' ? 'auto' : '100%' }}
                  position={{ x: 0, y: 0 }}
                  disableDragging={true}
                  dragGrid={snapToGrid ? [10 * scale, 10 * scale] : undefined}
                  resizeGrid={snapToGrid && layer.type === 'shape' ? [10 * scale, 10 * scale] : undefined}
                  lockAspectRatio={layer.type !== 'shape'}
                  onResizeStop={(e, direction, ref, delta, position) => {
                    setIsDragging(false);
                    const newWidth = ref.offsetWidth / scale;
                    const newHeight = ref.offsetHeight / scale;

                    const dx = position.x;
                    const dy = position.y;
                    const dxGlobal = dx * cosAngle - dy * sinAngle;
                    const dyGlobal = dx * sinAngle + dy * cosAngle;

                    const updates: Partial<Layer> = {
                      width: newWidth,
                      height: newHeight,
                      x: layer.x + dxGlobal / scale,
                      y: layer.y + dyGlobal / scale
                    };

                    if (layer.type === 'text') {
                      const scaleFactor = newWidth / layer.width;
                      updates.fontSize = Math.round((layer.fontSize || 16) * scaleFactor);
                      updates.height = ref.offsetHeight / scale;
                    }

                    if (layer.type === 'group' && layer.children) {
                      const scaleX = newWidth / layer.width;
                      const scaleY = newHeight / layer.height;
                      updates.children = layer.children.map(child => {
                        const childUpdates = {
                          ...child,
                          x: child.x * scaleX,
                          y: child.y * scaleY,
                          width: (child.width || 100) * scaleX,
                          height: (child.height || 100) * scaleY
                        };
                        if (child.type === 'text' && child.fontSize) {
                          childUpdates.fontSize = Math.round(child.fontSize * scaleY);
                        }
                        return childUpdates;
                      });
                    }

                    updateLayer(layer.id, updates);
                  }}
                  onResize={(e, direction, ref, delta, position) => {
                    if (!isDragging) setIsDragging(true);
                    if (layer.type === 'text') {
                      const newWidth = parseFloat(ref.style.width);
                      if (newWidth) {
                        const scaleFactor = newWidth / (layer.width * scale);
                        const newFontSizeCanvas = (layer.fontSize || 16) * scaleFactor;
                        const textSpan = ref.querySelector('span');
                        if (textSpan) {
                          textSpan.style.fontSize = `${newFontSizeCanvas * scale}px`;
                        }
                      }
                    }
                  }}
                  enableResizing={!layer.locked && activeLayerId === layer.id ? (layer.type === 'shape' ? { top:true, right:true, bottom:true, left:true, topRight:true, bottomRight:true, bottomLeft:true, topLeft:true } : { top:false, right:false, bottom:false, left:false, topRight:true, bottomRight:true, bottomLeft:true, topLeft:true }) : false}
                  resizeHandleStyles={activeLayerId === layer.id ? {
                    topLeft: { width: '10px', height: '10px', background: 'white', border: '2px solid var(--accent-color)', borderRadius: '50%', left: '-5px', top: '-5px' },
                    topRight: { width: '10px', height: '10px', background: 'white', border: '2px solid var(--accent-color)', borderRadius: '50%', right: '-5px', top: '-5px' },
                    bottomLeft: { width: '10px', height: '10px', background: 'white', border: '2px solid var(--accent-color)', borderRadius: '50%', left: '-5px', bottom: '-5px' },
                    bottomRight: { width: '10px', height: '10px', background: 'white', border: '2px solid var(--accent-color)', borderRadius: '50%', right: '-5px', bottom: '-5px' },
                    top: layer.type === 'shape' ? { width: '20px', height: '6px', background: 'white', border: '2px solid var(--accent-color)', borderRadius: '3px', top: '-3px', left: '50%', transform: 'translateX(-50%)', cursor: 'ns-resize' } : undefined,
                    bottom: layer.type === 'shape' ? { width: '20px', height: '6px', background: 'white', border: '2px solid var(--accent-color)', borderRadius: '3px', bottom: '-3px', left: '50%', transform: 'translateX(-50%)', cursor: 'ns-resize' } : undefined,
                    left: layer.type === 'shape' ? { width: '6px', height: '20px', background: 'white', border: '2px solid var(--accent-color)', borderRadius: '3px', left: '-3px', top: '50%', transform: 'translateY(-50%)', cursor: 'ew-resize' } : undefined,
                    right: layer.type === 'shape' ? { width: '6px', height: '20px', background: 'white', border: '2px solid var(--accent-color)', borderRadius: '3px', right: '-3px', top: '50%', transform: 'translateY(-50%)', cursor: 'ew-resize' } : undefined,
                  } : undefined}
                  onClick={(e: React.MouseEvent) => {
                    e.stopPropagation();
                    setContextMenu(prev => ({ ...prev, visible: false }));
                  }}
                  onContextMenu={(e: React.MouseEvent) => {
                    e.preventDefault();
                    e.stopPropagation();
                    if (!selectedLayerIds.includes(layer.id)) {
                      handleLayerSelectToggle(layer.id, e.shiftKey);
                    }
                    setContextMenu({
                      visible: true,
                      x: e.clientX,
                      y: e.clientY,
                      layerId: layer.id
                    });
                  }}
                  style={{
                    pointerEvents: 'auto',
                    border: activeLayerId === layer.id 
                      ? '2px solid var(--accent-color)' 
                      : (selectedLayerIds.includes(layer.id) ? '2px dashed var(--accent-color)' : '2px solid transparent'),
                    opacity: layer.opacity !== undefined ? layer.opacity : 1,
                    padding: 0,
                    mixBlendMode: (layer.mixBlendMode as React.CSSProperties['mixBlendMode']) || 'normal'
                  }}
                >
                  {/* Canva-style rotation handle placed at the bottom center of the selection box */}
                  {activeLayerId === layer.id && (
                    <div 
                      id={`rotation-handle-${layer.id}`}
                      style={{
                        position: 'absolute',
                        bottom: '-32px',
                        left: '50%',
                        transform: 'translateX(-50%)',
                        width: '24px',
                        height: '24px',
                        borderRadius: '50%',
                        background: 'white',
                        border: '1px solid var(--border-color)',
                        boxShadow: '0 2px 5px rgba(0,0,0,0.15)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        cursor: 'grab',
                        zIndex: 1000
                      }}
                      onMouseDown={(e) => handleRotationStart(e, layer)}
                      onClick={(e) => e.stopPropagation()}
                      title="Drag to rotate"
                    >
                      {/* Rotate arrows SVG */}
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#1F2937" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67" />
                      </svg>
                    </div>
                  )}
                  <div 
                    id={`rnd-container-${layer.id}`}
                    onMouseDown={(e) => handleDragStart(e, layer)}
                    onDoubleClick={() => {
                      if (layer.type === 'text') {
                        setEditingLayerId(layer.id);
                      }
                    }}
                    style={{
                      width: '100%', 
                      height: '100%',
                      boxSizing: 'border-box',
                      border: layer.borderWidth ? `${layer.borderWidth * scale}px solid ${layer.borderColor || '#000000'}` : 'none',
                      borderRadius: getShapeBorderRadius(layer),
                      overflow: layer.type === 'text' ? 'visible' : 'hidden',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      background: layer.type === 'shape' 
                        ? ((layer.shape === 'line' || layer.shape === 'triangle') ? 'transparent' : (layer.color || '#C5A880'))
                        : (layer.type === 'image_frame' ? '#E2E8F0' : 'transparent'),
                      cursor: layer.type === 'text' ? 'text' : undefined
                    }}
                  >
                    {layer.type === 'text' && (
                      <span 
                        contentEditable={editingLayerId === layer.id}
                        suppressContentEditableWarning={true}
                        onBlur={(e) => {
                          updateLayer(layer.id, { content: e.currentTarget.innerText });
                          setEditingLayerId(null);
                        }}
                        style={{ 
                          fontSize: (layer.fontSize || 16) * scale, 
                          color: layer.color,
                          fontFamily: (layer.fontFamily || 'Inter') + ', sans-serif',
                          fontWeight: layer.fontWeight || 'normal',
                          fontStyle: layer.fontStyle || 'normal',
                          textShadow: (layer.shadowOffsetX || layer.shadowOffsetY || layer.shadowBlur) 
                            ? `${layer.shadowOffsetX || 0}px ${layer.shadowOffsetY || 0}px ${layer.shadowBlur || 0}px ${layer.shadowColor || 'transparent'}` 
                            : (layer.hasShadow ? `0px ${2 * scale}px ${(layer.shadowBlur || 4) * scale}px ${layer.shadowColor || 'rgba(0,0,0,0.5)'}` : 'none'),
                          WebkitTextStroke: layer.outlineWidth ? `${layer.outlineWidth * scale}px ${layer.outlineColor || '#000000'}` : undefined,
                          backgroundColor: layer.textBackgroundColor || 'transparent',
                          padding: layer.textBackgroundColor ? `${10 * scale}px ${20 * scale}px` : '0',
                          borderRadius: layer.textBackgroundColor ? `${8 * scale}px` : '0',
                          userSelect: editingLayerId === layer.id ? 'text' : 'none',
                          width: '100%',
                          height: '100%',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: layer.alignment === 'left' ? 'flex-start' : (layer.alignment === 'right' ? 'flex-end' : 'center'),
                          textAlign: (layer.alignment as any) || 'center',
                          lineHeight: layer.lineHeight !== undefined ? layer.lineHeight : 1.2,
                          letterSpacing: layer.letterSpacing ? `${layer.letterSpacing * scale}px` : 'normal',
                          textTransform: (layer.textTransform as 'none' | 'uppercase' | 'lowercase' | 'capitalize') || 'none',
                          whiteSpace: 'normal',
                          wordBreak: 'break-word',
                          outline: 'none',
                          textDecoration: layer.textDecoration || 'none',
                          flexShrink: 0
                        }}
                      >
                        {layer.content}
                      </span>
                    )}
                    {layer.type === 'image_frame' && (
                      <>
                        {layer.src ? (
                          <img 
                            src={layer.src} 
                            alt="Frame content" 
                            draggable={false}
                            style={{ 
                              width: '100%', 
                              height: '100%', 
                              objectFit: 'cover',
                              transform: `scale(${layer.imageScale || 1}) translate(${layer.imageOffsetX || 0}px, ${layer.imageOffsetY || 0}px)`,
                              transformOrigin: 'center center',
                              pointerEvents: 'none'
                            }} 
                          />
                        ) : (
                          <ImageIcon color="var(--text-muted)" size={40 * scale} />
                        )}
                        {renderFrameOverlay(layer.frameStyle, layer.shape)}
                      </>
                    )}
                    {layer.type === 'image' && layer.src && (
                      <img 
                        src={layer.src} 
                        alt="Overlay" 
                        draggable={false}
                        style={{ 
                          width: '100%', 
                          height: '100%', 
                          objectFit: 'fill', 
                          pointerEvents: 'none',
                          mixBlendMode: (layer.mixBlendMode as React.CSSProperties['mixBlendMode']) || 'normal'
                        }} 
                      />
                    )}
                    {layer.type === 'shape' && layer.shape === 'triangle' && (
                      <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none" style={{ display: 'block' }}>
                        <polygon points="50,0 100,100 0,100" fill={layer.color || '#C5A880'} />
                      </svg>
                    )}
                    {layer.type === 'shape' && layer.shape === 'line' && (
                      <svg width="100%" height="100%" viewBox="0 0 100 10" preserveAspectRatio="none" style={{ display: 'block' }}>
                        <line x1="0" y1="5" x2="100" y2="5" stroke={layer.color || '#C5A880'} strokeWidth="4" />
                      </svg>
                    )}
                    {layer.type === 'group' && layer.children && (
                      <div style={{ width: '100%', height: '100%', position: 'relative', overflow: 'visible' }}>
                        {layer.children.map((child) => {
                          const childStyle: React.CSSProperties = {
                            position: 'absolute',
                            left: `${(child.x / layer.width) * 100}%`,
                            top: `${(child.y / layer.height) * 100}%`,
                            width: child.type === 'text' ? 'auto' : `${((child.width || 100) / layer.width) * 100}%`,
                            height: child.type === 'text' ? 'auto' : `${((child.height || 100) / layer.height) * 100}%`,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            transform: `rotate(${child.rotation || 0}deg)`,
                            pointerEvents: 'none'
                          };

                          return (
                            <div key={child.id} style={childStyle}>
                              {child.type === 'text' && (
                                <span style={{
                                  fontSize: (child.fontSize || 16) * scale,
                                  color: child.color,
                                  fontFamily: (child.fontFamily || 'Inter') + ', sans-serif',
                                  fontWeight: child.fontWeight || 'normal',
                                  fontStyle: child.fontStyle || 'normal',
                                  textDecoration: child.textDecoration || 'none',
                                  textShadow: child.hasShadow ? `0px ${2 * scale}px ${(child.shadowBlur || 4) * scale}px ${child.shadowColor || 'rgba(0,0,0,0.5)'}` : 'none',
                                  lineHeight: 1.2,
                                  whiteSpace: 'nowrap'
                                }}>
                                  {child.content}
                                </span>
                              )}
                              {child.type === 'shape' && child.shape !== 'triangle' && child.shape !== 'line' && (
                                <div style={{
                                  width: '100%',
                                  height: '100%',
                                  background: child.color || '#C5A880',
                                  border: child.borderWidth ? `${child.borderWidth * scale}px solid ${child.borderColor || '#000000'}` : 'none',
                                  borderRadius: getShapeBorderRadius(child)
                                }} />
                              )}
                              {child.type === 'shape' && child.shape === 'triangle' && (
                                <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none" style={{ display: 'block' }}>
                                  <polygon points="50,0 100,100 0,100" fill={child.color || '#C5A880'} />
                                </svg>
                              )}
                              {child.type === 'shape' && child.shape === 'line' && (
                                <svg width="100%" height="100%" viewBox="0 0 100 10" preserveAspectRatio="none" style={{ display: 'block' }}>
                                  <line x1="0" y1="5" x2="100" y2="5" stroke={child.color || '#C5A880'} strokeWidth="4" />
                                </svg>
                              )}
                              {child.type === 'image_frame' && (
                                <div style={{
                                  width: '100%',
                                  height: '100%',
                                  background: '#E2E8F0',
                                  borderRadius: getShapeBorderRadius(child),
                                  overflow: 'hidden',
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  position: 'relative'
                                }}>
                                  {child.src ? (
                                    <img src={child.src} alt="Group frame" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                  ) : (
                                    <span style={{ fontSize: '10px', color: '#94A3B8' }}>[Frame]</span>
                                  )}
                                  {renderFrameOverlay(child.frameStyle, child.shape)}
                                </div>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </Rnd>
              </div>
            );
          })}
        </div>

        {/* Floating Zoom / Workspace Badge */}
        <div style={{ position: 'absolute', bottom: '24px', right: '24px', background: 'var(--primary-color)', color: 'white', padding: '6px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '6px', boxShadow: 'var(--shadow-md)', opacity: 0.9 }}>
          <span>Workspace</span> • <span>100% Fit</span>
        </div>
      </main>

      {/* Right side: Tool Grid & Context-Aware Properties Panel */}
      <aside className="tools-sidebar" style={{ borderRight: 'none', borderLeft: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column', height: '100%', width: '340px' }}>
        
        {/* Right sidebar tab selector */}
        <div style={{ display: 'flex', borderBottom: '1px solid var(--border-color)', marginBottom: '16px', gap: '5px' }}>
          <button 
            type="button"
            onClick={() => { setRightSidebarTab('elements'); setElementSubPanel('main'); }}
            style={{
              flex: 1, padding: '12px 0', border: 'none', background: 'none', fontSize: '12px', fontWeight: 'bold',
              color: rightSidebarTab === 'elements' ? 'var(--accent-color)' : 'var(--text-secondary)',
              borderBottom: rightSidebarTab === 'elements' ? '2px solid var(--accent-color)' : 'none',
              cursor: 'pointer'
            }}
          >Add Element</button>
          <button 
            type="button"
            onClick={() => { setRightSidebarTab('verses'); setElementSubPanel('main'); }}
            style={{
              flex: 1, padding: '12px 0', border: 'none', background: 'none', fontSize: '12px', fontWeight: 'bold',
              color: rightSidebarTab === 'verses' ? 'var(--accent-color)' : 'var(--text-secondary)',
              borderBottom: rightSidebarTab === 'verses' ? '2px solid var(--accent-color)' : 'none',
              cursor: 'pointer'
            }}
          >Verses</button>
          <button 
            type="button"
            onClick={() => { setRightSidebarTab('graphics'); setElementSubPanel('main'); }}
            style={{
              flex: 1, padding: '12px 0', border: 'none', background: 'none', fontSize: '12px', fontWeight: 'bold',
              color: rightSidebarTab === 'graphics' ? 'var(--accent-color)' : 'var(--text-secondary)',
              borderBottom: rightSidebarTab === 'graphics' ? '2px solid var(--accent-color)' : 'none',
              cursor: 'pointer'
            }}
          >Graphics</button>
          <button 
            type="button"
            onClick={() => { setRightSidebarTab('flowers'); setElementSubPanel('main'); }}
            style={{
              flex: 1, padding: '12px 0', border: 'none', background: 'none', fontSize: '12px', fontWeight: 'bold',
              color: rightSidebarTab === 'flowers' ? 'var(--accent-color)' : 'var(--text-secondary)',
              borderBottom: rightSidebarTab === 'flowers' ? '2px solid var(--accent-color)' : 'none',
              cursor: 'pointer'
            }}
          >Flowers</button>
        </div>

        {/* Tab 1: Elements */}
        {rightSidebarTab === 'elements' && (
          <div>
            {elementSubPanel === 'main' && (
              <div>
                <h2 style={{ fontSize: '16px', marginBottom: '12px', fontWeight: 'bold' }}>Add Basic Elements</h2>
                {/* Sleek Tool Grid */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '24px' }}>
                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '15px 10px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => setLayers([...layers, { id: Date.now().toString(), type: 'text', content: 'New Text', x: 100, y: 100, fontSize: 60, color: '#1E252B', fontFamily: 'Inter', width: 400, height: 100, visible: true, rotation: 0 }])}
                  >
                    <Type size={20} style={{ color: 'var(--accent-color)', marginBottom: '6px' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Text</span>
                  </button>
                  
                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '15px 10px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => setElementSubPanel('frame_selector')}
                  >
                    <ImageIcon size={20} style={{ color: 'var(--accent-color)', marginBottom: '6px' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Frame</span>
                  </button>
                  
                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '15px 10px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => setElementSubPanel('shape_selector')}
                  >
                    <Square size={20} style={{ color: 'var(--accent-color)', marginBottom: '6px' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Shape</span>
                  </button>
                  
                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '15px 10px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => overlayInputRef.current?.click()}
                  >
                    <FileImage size={20} style={{ color: 'var(--accent-color)', marginBottom: '6px' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Photo</span>
                  </button>
                </div>
              </div>
            )}

            {elementSubPanel === 'shape_selector' && (
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
                  <button 
                    type="button" 
                    onClick={() => setElementSubPanel('main')} 
                    style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '4px' }}
                  >
                    <ChevronLeft size={18} style={{ color: 'var(--text-secondary)' }} />
                  </button>
                  <h2 style={{ fontSize: '16px', fontWeight: 'bold', margin: 0 }}>Select Shape</h2>
                </div>
                
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '12px 8px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'shape', shape: 'square', color: '#C5A880', x: 250, y: 250, width: 200, height: 200, visible: true, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '20px', height: '20px', background: 'var(--accent-color)', marginBottom: '6px' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Square / Box</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '12px 8px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'shape', shape: 'circle', color: '#C5A880', x: 250, y: 250, width: 200, height: 200, visible: true, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '20px', height: '20px', borderRadius: '50%', background: 'var(--accent-color)', marginBottom: '6px' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Circle</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '12px 8px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'shape', shape: 'triangle', color: '#C5A880', x: 250, y: 250, width: 200, height: 200, visible: true, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="var(--accent-color)" style={{ marginBottom: '6px' }}>
                      <polygon points="12,2 2,22 22,22" />
                    </svg>
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Triangle</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '12px 8px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'shape', shape: 'rounded-rectangle', color: '#C5A880', x: 250, y: 250, width: 200, height: 200, visible: true, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '24px', height: '18px', borderRadius: '4px', background: 'var(--accent-color)', marginBottom: '6px' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Rounded Rect</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '12px 8px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'shape', shape: 'oval', color: '#C5A880', x: 250, y: 250, width: 220, height: 140, visible: true, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '26px', height: '16px', borderRadius: '50%', background: 'var(--accent-color)', marginBottom: '6px' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Oval</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '12px 8px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'shape', shape: 'arch', color: '#C5A880', x: 250, y: 250, width: 200, height: 280, visible: true, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '20px', height: '26px', borderRadius: '10px 10px 0 0', background: 'var(--accent-color)', marginBottom: '6px' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Arch</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '12px 8px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'shape', shape: 'line', color: '#C5A880', x: 100, y: 300, width: 600, height: 20, visible: true, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '24px', height: '3px', background: 'var(--accent-color)', margin: '8px 0 9px 0' }} />
                    <span style={{ fontSize: '11px', fontWeight: 'bold' }}>Line Spacer</span>
                  </button>
                </div>
              </div>
            )}

            {elementSubPanel === 'frame_selector' && (
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
                  <button 
                    type="button" 
                    onClick={() => setElementSubPanel('main')} 
                    style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '4px' }}
                  >
                    <ChevronLeft size={18} style={{ color: 'var(--text-secondary)' }} />
                  </button>
                  <h2 style={{ fontSize: '16px', fontWeight: 'bold', margin: 0 }}>Select Frame</h2>
                </div>
                
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '10px 6px', borderRadius: 'var(--radius-md)', border: '2px dashed var(--accent-color)', background: 'rgba(197, 168, 128, 0.05)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'circle', frameStyle: 'custom', x: 200, y: 200, width: 300, height: 300, visible: true, src: null, rotation: 0, borderWidth: 2, borderColor: '#C5A880' }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '28px', height: '28px', border: '2px dashed var(--accent-color)', borderRadius: '50%', background: '#F8FAFC', marginBottom: '4px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <span style={{ fontSize: '12px', color: 'var(--accent-color)', fontWeight: 'bold' }}>+</span>
                    </div>
                    <span style={{ fontSize: '10px', fontWeight: 'bold', color: 'var(--accent-color)' }}>Custom Frame</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '10px 6px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'square', frameStyle: 'simple', x: 200, y: 200, width: 300, height: 300, visible: true, src: null, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '28px', height: '28px', border: '1px solid #CBD5E1', background: '#F8FAFC', marginBottom: '4px' }} />
                    <span style={{ fontSize: '10px', fontWeight: 'bold' }}>Simple Square</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '10px 6px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'circle', frameStyle: 'simple', x: 200, y: 200, width: 300, height: 300, visible: true, src: null, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '28px', height: '28px', border: '1px solid #CBD5E1', borderRadius: '50%', background: '#F8FAFC', marginBottom: '4px' }} />
                    <span style={{ fontSize: '10px', fontWeight: 'bold' }}>Simple Circle</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '10px 6px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'square', frameStyle: 'gold', x: 200, y: 200, width: 300, height: 300, visible: true, src: null, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '28px', height: '28px', border: '2px double #D4AF37', background: '#F8FAFC', marginBottom: '4px' }} />
                    <span style={{ fontSize: '10px', fontWeight: 'bold' }}>Gold Foil Frame</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '10px 6px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'square', frameStyle: 'mourning', x: 200, y: 200, width: 300, height: 300, visible: true, src: null, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '28px', height: '28px', border: '2px solid black', background: '#F8FAFC', position: 'relative', overflow: 'hidden', marginBottom: '4px' }}>
                      <div style={{ position: 'absolute', top: '3px', right: '-8px', width: '20px', height: '4px', background: 'black', transform: 'rotate(45deg)' }} />
                    </div>
                    <span style={{ fontSize: '10px', fontWeight: 'bold' }}>Mourning Ribbon</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '10px 6px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'circle', frameStyle: 'rosary', x: 200, y: 200, width: 300, height: 300, visible: true, src: null, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '28px', height: '28px', border: '1px solid #C5A880', borderRadius: '50%', background: '#F8FAFC', position: 'relative', marginBottom: '4px' }}>
                      <div style={{ position: 'absolute', top: '-2px', left: '-2px', right: '-2px', bottom: '-2px', border: '1px dotted #C5A880', borderRadius: '50%' }} />
                    </div>
                    <span style={{ fontSize: '10px', fontWeight: 'bold' }}>Rosary Circle</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '10px 6px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'square', frameStyle: 'floral', x: 200, y: 200, width: 300, height: 300, visible: true, src: null, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '28px', height: '28px', border: '1px solid #C5A880', background: '#F8FAFC', position: 'relative', marginBottom: '4px' }}>
                      <div style={{ position: 'absolute', top: 1, left: 1, color: '#C5A880', fontSize: '6px' }}>✦</div>
                      <div style={{ position: 'absolute', top: 1, right: 1, color: '#C5A880', fontSize: '6px' }}>✦</div>
                    </div>
                    <span style={{ fontSize: '10px', fontWeight: 'bold' }}>Floral Corner</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '10px 6px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'square', frameStyle: 'silver', x: 200, y: 200, width: 300, height: 300, visible: true, src: null, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '28px', height: '28px', border: '2px double #94A3B8', background: '#F8FAFC', marginBottom: '4px' }} />
                    <span style={{ fontSize: '10px', fontWeight: 'bold' }}>Silver Frame</span>
                  </button>

                  <button 
                    type="button"
                    className="aspect-ratio-card" 
                    style={{ padding: '10px 6px', borderRadius: 'var(--radius-md)' }}
                    onClick={() => {
                      setLayers([...layers, { id: Date.now().toString(), type: 'image_frame', shape: 'arch', frameStyle: 'gold', x: 200, y: 200, width: 300, height: 400, visible: true, src: null, rotation: 0 }]);
                      setElementSubPanel('main');
                    }}
                  >
                    <div style={{ width: '28px', height: '36px', border: '2px solid #D4AF37', borderRadius: '14px 14px 0 0', background: '#F8FAFC', marginBottom: '4px' }} />
                    <span style={{ fontSize: '10px', fontWeight: 'bold' }}>Elegant Arch</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Tab 2: Verses */}
        {rightSidebarTab === 'verses' && (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflowY: 'hidden' }}>
            <h2 style={{ fontSize: '16px', marginBottom: '8px', fontWeight: 'bold' }}>Memorial Verses</h2>
            <p style={{ fontSize: '11px', color: 'var(--text-secondary)', marginBottom: '15px' }}>Click on a verse to insert it as a text layer.</p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', overflowY: 'auto', paddingRight: '5px', flex: 1, maxHeight: '350px' }}>
              {[
                "In Loving Memory",
                "Rest in Peace",
                "Forever in Our Hearts",
                "Always loved, never forgotten.",
                "Until we meet again in Heaven.",
                "Gone from our sight, but never from our hearts.",
                "The Lord is my shepherd; I shall not want. - Psalm 23",
                "He will wipe away every tear from their eyes. - Revelation 21:4",
                "To live in hearts we leave behind is not to die. - Thomas Campbell",
                "May God grant eternal rest to their beautiful soul.",
                "A life so beautifully lived deserves to be beautifully remembered."
              ].map((verse, idx) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => setLayers([...layers, { id: Date.now().toString(), type: 'text', content: verse, x: 140, y: 200 + idx * 20, fontSize: 50, color: '#1E252B', fontFamily: 'Inter', width: 800, height: 100, visible: true, rotation: 0 }])}
                  style={{
                    padding: '10px 12px',
                    textAlign: 'left',
                    background: 'white',
                    border: '1px solid var(--border-color)',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: '12px',
                    lineHeight: '1.4',
                    color: 'var(--text-primary)',
                    cursor: 'pointer',
                    transition: 'all 0.2s'
                  }}
                >
                  {verse}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Tab 3: Graphics */}
        {rightSidebarTab === 'graphics' && (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflowY: 'hidden' }}>
            <h2 style={{ fontSize: '16px', marginBottom: '8px', fontWeight: 'bold' }}>Memorial Graphics</h2>
            <p style={{ fontSize: '11px', color: 'var(--text-secondary)', marginBottom: '15px' }}>Click to insert stickers and borders.</p>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', overflowY: 'auto', paddingRight: '5px', flex: 1, maxHeight: '350px' }}>
              
              {/* Graphic 1: Classic Cross */}
              <button
                type="button"
                className="aspect-ratio-card"
                style={{ padding: '10px', height: '100px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}
                onClick={() => {
                  const svgCross = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M 45,10 H 55 V 35 H 80 V 45 H 55 V 90 H 45 V 45 H 20 V 35 H 45 Z" fill="%231E252B"/></svg>`;
                  setLayers([...layers, { id: Date.now().toString(), type: 'image', src: svgCross, x: 440, y: 100, width: 200, height: 200, visible: true, rotation: 0 }]);
                }}
              >
                <svg viewBox="0 0 100 100" width="36" height="36"><path d="M 45,10 H 55 V 35 H 80 V 45 H 55 V 90 H 45 V 45 H 20 V 35 H 45 Z" fill="var(--text-primary)" /></svg>
                <span style={{ fontSize: '10px', marginTop: '6px', fontWeight: 'bold' }}>Latin Cross</span>
              </button>

              {/* Graphic 2: Candle */}
              <button
                type="button"
                className="aspect-ratio-card"
                style={{ padding: '10px', height: '100px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}
                onClick={() => {
                  const svgCandle = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M 42,55 H 58 V 95 H 42 Z M 50,15 C 55,28 50,45 50,45 C 50,45 45,28 50,15 Z" fill="%23C5A880"/><path d="M 40,95 H 60" stroke="%231E252B" stroke-width="4"/></svg>`;
                  setLayers([...layers, { id: Date.now().toString(), type: 'image', src: svgCandle, x: 440, y: 100, width: 200, height: 200, visible: true, rotation: 0 }]);
                }}
              >
                <svg viewBox="0 0 100 100" width="36" height="36"><path d="M 42,55 H 58 V 95 H 42 Z M 50,15 C 55,28 50,45 50,45 C 50,45 45,28 50,15 Z" fill="var(--accent-color)"/><path d="M 40,95 H 60" stroke="var(--text-primary)" strokeWidth="4"/></svg>
                <span style={{ fontSize: '10px', marginTop: '6px', fontWeight: 'bold' }}>Candle</span>
              </button>

              {/* Graphic 3: Dove */}
              <button
                type="button"
                className="aspect-ratio-card"
                style={{ padding: '10px', height: '100px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}
                onClick={() => {
                  const svgDove = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M 70,30 C 50,25 35,40 30,55 C 25,60 15,55 10,65 C 20,70 30,65 35,60 C 45,55 55,60 65,55 C 75,50 80,40 70,30 Z" fill="%231E252B"/></svg>`;
                  setLayers([...layers, { id: Date.now().toString(), type: 'image', src: svgDove, x: 440, y: 100, width: 200, height: 200, visible: true, rotation: 0 }]);
                }}
              >
                <svg viewBox="0 0 100 100" width="36" height="36"><path d="M 70,30 C 50,25 35,40 30,55 C 25,60 15,55 10,65 C 20,70 30,65 35,60 C 45,55 55,60 65,55 C 75,50 80,40 70,30 Z" fill="var(--text-primary)" /></svg>
                <span style={{ fontSize: '10px', marginTop: '6px', fontWeight: 'bold' }}>Dove</span>
              </button>

              {/* Graphic 4: Elegant Border Frame */}
              <button
                type="button"
                className="aspect-ratio-card"
                style={{ padding: '10px', height: '100px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}
                onClick={() => {
                  const svgBorder = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="none"><rect x="5" y="5" width="90" height="90" stroke="%23C5A880" stroke-width="4"/><rect x="10" y="10" width="80" height="80" stroke="%231E252B" stroke-width="1"/></svg>`;
                  setLayers([...layers, { id: Date.now().toString(), type: 'image', src: svgBorder, x: 54, y: 54, width: 972, height: 972, visible: true, rotation: 0 }]);
                }}
              >
                <svg viewBox="0 0 100 100" width="36" height="36" fill="none"><rect x="10" y="10" width="80" height="80" stroke="var(--accent-color)" strokeWidth="4"/><rect x="20" y="20" width="60" height="60" stroke="var(--text-primary)" strokeWidth="1"/></svg>
                <span style={{ fontSize: '10px', marginTop: '6px', fontWeight: 'bold' }}>Border</span>
              </button>
            </div>
          </div>
        )}

        {/* Tab 4: Flowers */}
        {rightSidebarTab === 'flowers' && (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflowY: 'hidden' }}>
            <h2 style={{ fontSize: '16px', marginBottom: '8px', fontWeight: 'bold' }}>Floral Designs</h2>
            <p style={{ fontSize: '11px', color: 'var(--text-secondary)', marginBottom: '15px' }}>Click to insert beautiful floral overlays.</p>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', overflowY: 'auto', paddingRight: '5px', flex: 1, maxHeight: '350px' }}>
              {[
                { id: 'floral_white_roses', name: 'White Roses' },
                { id: 'floral_gold_leaves', name: 'Gold Leaves' },
                { id: 'floral_cherry_blossom', name: 'Cherry Blossom' },
                { id: 'floral_forget_me_not', name: 'Forget-me-not' },
                { id: 'floral_olive_branch', name: 'Olive Branch' },
                { id: 'floral_lavender', name: 'Lavender' },
                { id: 'floral_lilies_frame', name: 'Lilies Frame' },
                { id: 'floral_peonies', name: 'Peonies' },
                { id: 'floral_ferns_corner', name: 'Ferns Corner' },
                { id: 'floral_daisy_divider', name: 'Daisy Divider' },
                { id: 'original_golden_floral', name: 'Golden Floral' },
                { id: 'original_classic_ivory', name: 'Classic Ivory' },
                { id: 'original_dark_moody', name: 'Dark Moody' },
                { id: 'original_subtle_corner', name: 'Subtle Corner' },
                { id: 'original_elegant_geometric', name: 'Elegant Geometric' },
                { id: 'original_blue_hydrangea', name: 'Blue Hydrangea' },
                { id: 'original_soft_blush', name: 'Soft Blush' },
                { id: 'original_vintage_sepia', name: 'Vintage Sepia' },
                { id: 'original_white_orchid', name: 'White Orchid' },
                { id: 'original_peace_lily', name: 'Peace Lily' },
              ].map(flower => (
                <button
                  key={flower.id}
                  type="button"
                  className="aspect-ratio-card"
                  style={{ padding: '0', height: '120px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}
                  onClick={() => {
                    setLayers([...layers, { 
                      id: Date.now().toString(), 
                      type: 'image', 
                      src: `/flowers/${flower.id}.png`, 
                      x: 100, y: 100, 
                      width: 400, height: 400, 
                      visible: true, 
                      rotation: 0,
                      mixBlendMode: 'multiply' 
                    }]);
                  }}
                >
                  <img src={`/flowers/${flower.id}.png`} alt={flower.name} style={{ width: '100%', height: '100%', objectFit: 'contain', mixBlendMode: 'multiply' }} />
                  <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, background: 'rgba(255,255,255,0.9)', padding: '4px', fontSize: '10px', fontWeight: 'bold', textAlign: 'center', borderTop: '1px solid var(--border-color)' }}>
                    {flower.name}
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* File inputs */}
        <input type="file" ref={overlayInputRef} style={{ display: 'none' }} accept="image/*" 
          onChange={async (e) => {
            if (e.target.files && e.target.files[0]) {
              try {
                const file = e.target.files[0];
                const localUrl = URL.createObjectURL(file);
                const tempId = Date.now().toString();
                setLayers(prev => [...prev, { id: tempId, type: 'image', src: localUrl, x: 100, y: 100, width: 300, height: 300, visible: true }]);
                
                const serverUrl = await uploadFile(file);
                setLayers(prev => prev.map(l => l.id === tempId ? { ...l, src: serverUrl } : l));
              } catch (err) {
                console.error(err);
                alert('Failed to upload image overlay.');
              }
            }
          }} 
        />
        <input type="file" ref={bgInputRef} style={{ display: 'none' }} accept="image/*" onChange={handleBgUpload} />

        {/* Separator */}
        <div style={{ height: '1px', background: 'var(--border-color)', margin: '0 0 24px 0' }} />

        {/* Context-Aware Properties Panel */}
        <div style={{ flex: 1, overflowY: 'auto' }}>
          
          {/* Shared Layer Controls (Alignment & Rotation) */}
          {activeLayer && (
            <div style={{ borderBottom: '1px solid var(--border-color)', paddingBottom: '20px', marginBottom: '20px' }}>
              {/* Layer Alignment Utilities */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                <label style={{ fontSize: '11px', fontWeight: 'bold', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Alignment</label>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '6px' }}>
                  <button type="button" onClick={() => alignActiveLayer('left')} className="btn btn-secondary" style={{ padding: '6px 4px', fontSize: '11px' }}>Left</button>
                  <button type="button" onClick={() => alignActiveLayer('center')} className="btn btn-secondary" style={{ padding: '6px 4px', fontSize: '11px' }}>H-Center</button>
                  <button type="button" onClick={() => alignActiveLayer('right')} className="btn btn-secondary" style={{ padding: '6px 4px', fontSize: '11px' }}>Right</button>
                  <button type="button" onClick={() => alignActiveLayer('top')} className="btn btn-secondary" style={{ padding: '6px 4px', fontSize: '11px' }}>Top</button>
                  <button type="button" onClick={() => alignActiveLayer('middle')} className="btn btn-secondary" style={{ padding: '6px 4px', fontSize: '11px' }}>V-Center</button>
                  <button type="button" onClick={() => alignActiveLayer('bottom')} className="btn btn-secondary" style={{ padding: '6px 4px', fontSize: '11px' }}>Bottom</button>
                </div>
              </div>

              {/* Rotation Slider & Buttons */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                  <span>Rotation</span>
                  <span>{activeLayer.rotation || 0}°</span>
                </div>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <input 
                    type="range" min="0" max="360" step="1"
                    value={activeLayer.rotation || 0} 
                    onChange={(e) => rotateLayerAroundCenter(activeLayer.id, parseInt(e.target.value))}
                    style={{ flex: 1, accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                  />
                  <button 
                    type="button"
                    onClick={() => rotateLayerAroundCenter(activeLayer.id, ((activeLayer.rotation || 0) + 345) % 360)}
                    className="btn btn-secondary"
                    style={{ padding: '4px 8px', fontSize: '11px', minWidth: '40px' }}
                  >-15°</button>
                  <button 
                    type="button"
                    onClick={() => rotateLayerAroundCenter(activeLayer.id, ((activeLayer.rotation || 0) + 15) % 360)}
                    className="btn btn-secondary"
                    style={{ padding: '4px 8px', fontSize: '11px', minWidth: '40px' }}
                  >+15°</button>
                </div>
              </div>
            </div>
          )}
          
          {/* Case 1: No active layer - Canvas Properties */}
          {!activeLayer && (
            <div>
              <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Canvas Properties</h3>
              
              {/* Tab Headers */}
              <div style={{ display: 'flex', borderBottom: '1px solid var(--border-color)', marginBottom: '18px', gap: '5px' }}>
                <button 
                  onClick={() => setBackgroundType('color')}
                  style={{
                    flex: 1, padding: '8px 0', border: 'none', background: 'none', fontSize: '12px', fontWeight: 'bold',
                    color: backgroundType === 'color' ? 'var(--accent-color)' : 'var(--text-secondary)',
                    borderBottom: backgroundType === 'color' ? '2px solid var(--accent-color)' : 'none',
                    cursor: 'pointer'
                  }}
                >Solid</button>
                <button 
                  onClick={() => setBackgroundType('image')}
                  style={{
                    flex: 1, padding: '8px 0', border: 'none', background: 'none', fontSize: '12px', fontWeight: 'bold',
                    color: backgroundType === 'image' ? 'var(--accent-color)' : 'var(--text-secondary)',
                    borderBottom: backgroundType === 'image' ? '2px solid var(--accent-color)' : 'none',
                    cursor: 'pointer'
                  }}
                >Image</button>
              </div>

              {/* Tab Body: Solid Color */}
              {backgroundType === 'color' && (
                <div className="input-group">
                  <label>Background Color</label>
                  <input 
                    type="color" 
                    value={solidColor} 
                    onChange={(e) => setSolidColor(e.target.value)}
                    style={{ padding: '0', height: '40px', cursor: 'pointer' }}
                  />
                </div>
              )}



              {/* Tab Body: Image */}
              {backgroundType === 'image' && (
                <div>
                  <div className="input-group">
                    <label>Background Image</label>
                    <button 
                      className="btn" 
                      style={{ width: '100%', border: '1px solid var(--border-color)', background: 'var(--bg-color)', gap: '8px' }}
                      onClick={() => bgInputRef.current?.click()}
                    >
                      <Wallpaper size={16} /> Choose Image
                    </button>
                  </div>

                  {background && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '16px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                        <span>Image Opacity</span>
                        <span>{Math.round(bgOpacity * 100)}%</span>
                      </div>
                      <input 
                        type="range" min="0" max="1" step="0.05"
                        value={bgOpacity} 
                        onChange={(e) => setBgOpacity(parseFloat(e.target.value))}
                        style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                      />
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* Case 2: Text Layer Active */}
          {activeLayer && activeLayer.type === 'text' && (
            <div>
              <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Edit Text</h3>
              
              <div className="input-group">
                <label>Content</label>
                <input 
                  value={activeLayer.content || ''} 
                  onChange={(e) => updateLayer(activeLayer.id, { content: e.target.value })}
                />
              </div>

              <div className="input-group" style={{ position: 'relative' }}>
                <label>Font Family</label>
                <div 
                  onClick={() => setShowFontDropdown(!showFontDropdown)}
                  style={{
                    padding: '8px 12px',
                    border: '1px solid var(--border-color)',
                    borderRadius: 'var(--radius-sm)',
                    background: 'var(--surface-color)',
                    cursor: 'pointer',
                    fontFamily: activeLayer.fontFamily || 'Inter',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    fontSize: '14px'
                  }}
                >
                  {activeLayer.fontFamily || 'Inter'}
                  <span style={{ fontSize: '10px' }}>▼</span>
                </div>
                {showFontDropdown && (
                  <>
                    <div 
                      style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 99 }} 
                      onClick={() => setShowFontDropdown(false)} 
                    />
                    <div style={{
                      position: 'absolute',
                      top: '100%',
                      left: 0,
                      right: 0,
                      maxHeight: '250px',
                      overflowY: 'auto',
                      background: 'var(--surface-color)',
                      border: '1px solid var(--border-color)',
                      borderRadius: 'var(--radius-sm)',
                      zIndex: 100,
                      boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                      marginTop: '4px'
                    }}>
                      {GOOGLE_FONTS_LIBRARY.map(font => (
                        <div 
                          key={font}
                          onClick={() => {
                            updateLayer(activeLayer.id, { fontFamily: font });
                            setShowFontDropdown(false);
                          }}
                          style={{
                            padding: '10px 12px',
                            cursor: 'pointer',
                            fontFamily: font,
                            fontSize: '16px',
                            backgroundColor: (activeLayer.fontFamily || 'Inter') === font ? 'var(--accent-color)' : 'transparent',
                            color: (activeLayer.fontFamily || 'Inter') === font ? 'white' : 'var(--text-color)',
                            borderBottom: '1px solid var(--border-color)'
                          }}
                          onMouseEnter={(e) => e.currentTarget.style.backgroundColor = (activeLayer.fontFamily || 'Inter') === font ? 'var(--accent-color)' : 'rgba(0,0,0,0.05)'}
                          onMouseLeave={(e) => e.currentTarget.style.backgroundColor = (activeLayer.fontFamily || 'Inter') === font ? 'var(--accent-color)' : 'transparent'}
                        >
                          {font}
                        </div>
                      ))}
                    </div>
                  </>
                )}
              </div>

              <div className="input-group">
                <label>Font Size</label>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <input 
                    type="range" min="10" max="300" step="1"
                    value={activeLayer.fontSize || 16} 
                    onChange={(e) => updateLayer(activeLayer.id, { fontSize: Number(e.target.value) })}
                    style={{ flex: 1, accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                  />
                  <input 
                    type="number" 
                    value={activeLayer.fontSize || 16} 
                    onChange={(e) => updateLayer(activeLayer.id, { fontSize: Number(e.target.value) })}
                    style={{ width: '70px', textAlign: 'center' }}
                  />
                </div>
              </div>

              <div className="input-group">
                <label>Text Color</label>
                <input 
                  type="color" 
                  value={activeLayer.color || '#1E252B'} 
                  onChange={(e) => updateLayer(activeLayer.id, { color: e.target.value })}
                  style={{ padding: '0', height: '40px', cursor: 'pointer' }}
                />
              </div>

              <div className="input-group">
                <label>Text Style</label>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <button 
                    className="btn" 
                    style={{ flex: 1, padding: '8px', fontWeight: 'bold', background: activeLayer.fontWeight === 'bold' ? 'var(--accent-color)' : 'var(--bg-color)', color: activeLayer.fontWeight === 'bold' ? 'white' : 'var(--text-primary)', border: '1px solid var(--border-color)' }}
                    onClick={() => updateLayer(activeLayer.id, { fontWeight: activeLayer.fontWeight === 'bold' ? 'normal' : 'bold' })}
                  >B</button>
                  <button 
                    className="btn" 
                    style={{ flex: 1, padding: '8px', fontStyle: 'italic', background: activeLayer.fontStyle === 'italic' ? 'var(--accent-color)' : 'var(--bg-color)', color: activeLayer.fontStyle === 'italic' ? 'white' : 'var(--text-primary)', border: '1px solid var(--border-color)' }}
                    onClick={() => updateLayer(activeLayer.id, { fontStyle: activeLayer.fontStyle === 'italic' ? 'normal' : 'italic' })}
                  >I</button>
                  <button 
                    className="btn" 
                    style={{ flex: 1, padding: '8px', textDecoration: 'underline', background: activeLayer.textDecoration === 'underline' ? 'var(--accent-color)' : 'var(--bg-color)', color: activeLayer.textDecoration === 'underline' ? 'white' : 'var(--text-primary)', border: '1px solid var(--border-color)' }}
                    onClick={() => updateLayer(activeLayer.id, { textDecoration: activeLayer.textDecoration === 'underline' ? 'none' : 'underline' })}
                  >U</button>
                </div>
              </div>

              <div className="input-group">
                <label>Letter Case</label>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <button 
                    className="btn" 
                    style={{ flex: 1, padding: '8px', fontWeight: 'bold', background: activeLayer.textTransform === 'uppercase' ? 'var(--accent-color)' : 'var(--bg-color)', color: activeLayer.textTransform === 'uppercase' ? 'white' : 'var(--text-primary)', border: '1px solid var(--border-color)' }}
                    onClick={() => updateLayer(activeLayer.id, { textTransform: activeLayer.textTransform === 'uppercase' ? 'none' : 'uppercase' })}
                  >AA</button>
                  <button 
                    className="btn" 
                    style={{ flex: 1, padding: '8px', fontWeight: 'bold', background: activeLayer.textTransform === 'lowercase' ? 'var(--accent-color)' : 'var(--bg-color)', color: activeLayer.textTransform === 'lowercase' ? 'white' : 'var(--text-primary)', border: '1px solid var(--border-color)' }}
                    onClick={() => updateLayer(activeLayer.id, { textTransform: activeLayer.textTransform === 'lowercase' ? 'none' : 'lowercase' })}
                  >aa</button>
                  <button 
                    className="btn" 
                    style={{ flex: 1, padding: '8px', fontWeight: 'bold', background: activeLayer.textTransform === 'capitalize' ? 'var(--accent-color)' : 'var(--bg-color)', color: activeLayer.textTransform === 'capitalize' ? 'white' : 'var(--text-primary)', border: '1px solid var(--border-color)' }}
                    onClick={() => updateLayer(activeLayer.id, { textTransform: activeLayer.textTransform === 'capitalize' ? 'none' : 'capitalize' })}
                  >Aa</button>
                </div>
              </div>

              <div className="input-group">
                <label>Spacing</label>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                    <span>Letter Spacing</span>
                    <span>{activeLayer.letterSpacing || 0}</span>
                  </div>
                  <input 
                    type="range" min="-10" max="100" step="1"
                    value={activeLayer.letterSpacing || 0} 
                    onChange={(e) => updateLayer(activeLayer.id, { letterSpacing: Number(e.target.value) })}
                    style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                  />
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)', marginTop: '4px' }}>
                    <span>Line Height</span>
                    <span>{activeLayer.lineHeight !== undefined ? activeLayer.lineHeight : 1.2}</span>
                  </div>
                  <input 
                    type="range" min="0.5" max="3" step="0.1"
                    value={activeLayer.lineHeight !== undefined ? activeLayer.lineHeight : 1.2} 
                    onChange={(e) => updateLayer(activeLayer.id, { lineHeight: Number(e.target.value) })}
                    style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                  />
                </div>
              </div>

              {/* Opacity Slider */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                  <span>Opacity</span>
                  <span>{Math.round((activeLayer.opacity !== undefined ? activeLayer.opacity : 1) * 100)}%</span>
                </div>
                <input 
                  type="range" min="0" max="1" step="0.05"
                  value={activeLayer.opacity !== undefined ? activeLayer.opacity : 1} 
                  onChange={(e) => updateLayer(activeLayer.id, { opacity: parseFloat(e.target.value) })}
                  style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                />
              </div>

              <div style={{ height: '1px', background: 'var(--border-color)', margin: '20px 0' }} />
              
              {activeTextEffect === null ? (
                <button 
                  className="btn" 
                  style={{ width: '100%', background: 'var(--accent-color)', color: 'white', fontWeight: 'bold', padding: '10px' }} 
                  onClick={() => setActiveTextEffect('menu')}
                >
                  Effects <span>›</span>
                </button>
              ) : activeTextEffect === 'menu' ? (
                <>
                  <button className="btn" style={{ marginBottom: '16px', background: 'var(--bg-color)', border: '1px solid var(--border-color)', width: 'fit-content', padding: '6px 12px' }} onClick={() => setActiveTextEffect(null)}>
                    ‹ Back
                  </button>
                  <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Effects Menu</h3>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    <button className="btn" style={{ justifyContent: 'space-between', background: 'var(--bg-color)', border: '1px solid var(--border-color)', padding: '12px 16px' }} onClick={() => setActiveTextEffect('shadow')}>
                      Drop Shadow <span>›</span>
                    </button>
                    <button className="btn" style={{ justifyContent: 'space-between', background: 'var(--bg-color)', border: '1px solid var(--border-color)', padding: '12px 16px' }} onClick={() => setActiveTextEffect('outline')}>
                      Outline <span>›</span>
                    </button>
                    <button className="btn" style={{ justifyContent: 'space-between', background: 'var(--bg-color)', border: '1px solid var(--border-color)', padding: '12px 16px' }} onClick={() => setActiveTextEffect('background')}>
                      Background Highlight <span>›</span>
                    </button>
                    <button className="btn" style={{ justifyContent: 'space-between', background: 'var(--bg-color)', border: '1px solid var(--border-color)', padding: '12px 16px' }} onClick={() => setActiveTextEffect('glow')}>
                      Glow <span>›</span>
                    </button>
                    <button className="btn" style={{ justifyContent: 'space-between', background: 'var(--bg-color)', border: '1px solid var(--border-color)', padding: '12px 16px' }} onClick={() => setActiveTextEffect('echo')}>
                      Echo <span>›</span>
                    </button>
                  </div>
                </>
              ) : activeTextEffect === 'glow' ? (
                <>
                  <button className="btn" style={{ marginBottom: '16px', background: 'var(--bg-color)', border: '1px solid var(--border-color)', width: 'fit-content', padding: '6px 12px' }} onClick={() => setActiveTextEffect('menu')}>
                    ‹ Back
                  </button>
                  <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Glow</h3>
                  <div className="input-group">
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                      <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                        <div style={{ display: 'flex', flex: 1, gap: '8px', alignItems: 'center' }}>
                          <input 
                            type="range" min="0" max="50" step="1"
                            value={activeLayer.shadowBlur || 0} 
                            onChange={(e) => updateLayer(activeLayer.id, { shadowBlur: Number(e.target.value), shadowOffsetX: 0, shadowOffsetY: 0 })}
                            style={{ flex: 1, accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                          />
                          <input 
                            type="number" placeholder="Intensity"
                            value={activeLayer.shadowBlur || 0} 
                            onChange={(e) => updateLayer(activeLayer.id, { shadowBlur: Number(e.target.value), shadowOffsetX: 0, shadowOffsetY: 0 })}
                            style={{ width: '60px', textAlign: 'center' }}
                          />
                        </div>
                        <input 
                          type="color" 
                          value={activeLayer.shadowColor || '#000000'} 
                          onChange={(e) => updateLayer(activeLayer.id, { shadowColor: e.target.value, shadowOffsetX: 0, shadowOffsetY: 0 })}
                          style={{ flex: 1, padding: '0', height: '36px', cursor: 'pointer' }}
                        />
                      </div>
                      <button 
                        className="btn btn-secondary" 
                        style={{ marginTop: '8px' }}
                        onClick={() => updateLayer(activeLayer.id, { shadowOffsetX: 0, shadowOffsetY: 0, shadowBlur: 0, shadowColor: 'transparent' })}
                      >Remove Glow</button>
                    </div>
                  </div>
                </>
              ) : activeTextEffect === 'echo' ? (
                <>
                  <button className="btn" style={{ marginBottom: '16px', background: 'var(--bg-color)', border: '1px solid var(--border-color)', width: 'fit-content', padding: '6px 12px' }} onClick={() => setActiveTextEffect('menu')}>
                    ‹ Back
                  </button>
                  <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Echo</h3>
                  <div className="input-group">
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                      <div style={{ display: 'flex', gap: '8px' }}>
                        <div style={{ display: 'flex', flex: 1, gap: '8px', alignItems: 'center' }}>
                          <input 
                            type="range" min="-50" max="50" step="1"
                            value={activeLayer.shadowOffsetX || 0} 
                            onChange={(e) => updateLayer(activeLayer.id, { shadowOffsetX: Number(e.target.value), shadowOffsetY: Number(e.target.value), shadowBlur: 0 })}
                            style={{ flex: 1, accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                          />
                          <input 
                            type="number" placeholder="Offset"
                            value={activeLayer.shadowOffsetX || 0} 
                            onChange={(e) => updateLayer(activeLayer.id, { shadowOffsetX: Number(e.target.value), shadowOffsetY: Number(e.target.value), shadowBlur: 0 })}
                            style={{ width: '60px', textAlign: 'center' }}
                          />
                        </div>
                        <input 
                          type="color" 
                          value={activeLayer.shadowColor || '#000000'} 
                          onChange={(e) => updateLayer(activeLayer.id, { shadowColor: e.target.value, shadowBlur: 0 })}
                          style={{ flex: 1, padding: '0', height: '36px', cursor: 'pointer' }}
                        />
                      </div>
                      <button 
                        className="btn btn-secondary" 
                        style={{ marginTop: '8px' }}
                        onClick={() => updateLayer(activeLayer.id, { shadowOffsetX: 0, shadowOffsetY: 0, shadowBlur: 0, shadowColor: 'transparent' })}
                      >Remove Echo</button>
                    </div>
                  </div>
                </>
              ) : activeTextEffect === 'shadow' ? (
                <>
                  <button className="btn" style={{ marginBottom: '16px', background: 'var(--bg-color)', border: '1px solid var(--border-color)', width: 'fit-content', padding: '6px 12px' }} onClick={() => setActiveTextEffect('menu')}>
                    ‹ Back
                  </button>
                  <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Drop Shadow</h3>
                  <div className="input-group">
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                          <span style={{ fontSize: '11px', width: '20px' }}>X</span>
                          <input 
                            type="range" min="-50" max="50" step="1"
                            value={activeLayer.shadowOffsetX || 0} 
                            onChange={(e) => updateLayer(activeLayer.id, { shadowOffsetX: Number(e.target.value) })}
                            style={{ flex: 1, accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                          />
                          <input 
                            type="number"
                            value={activeLayer.shadowOffsetX || 0} 
                            onChange={(e) => updateLayer(activeLayer.id, { shadowOffsetX: Number(e.target.value) })}
                            style={{ width: '50px', textAlign: 'center' }}
                          />
                        </div>
                        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                          <span style={{ fontSize: '11px', width: '20px' }}>Y</span>
                          <input 
                            type="range" min="-50" max="50" step="1"
                            value={activeLayer.shadowOffsetY || 0} 
                            onChange={(e) => updateLayer(activeLayer.id, { shadowOffsetY: Number(e.target.value) })}
                            style={{ flex: 1, accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                          />
                          <input 
                            type="number"
                            value={activeLayer.shadowOffsetY || 0} 
                            onChange={(e) => updateLayer(activeLayer.id, { shadowOffsetY: Number(e.target.value) })}
                            style={{ width: '50px', textAlign: 'center' }}
                          />
                        </div>
                      </div>
                      <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                        <span style={{ fontSize: '11px', width: '20px' }}>Blur</span>
                        <input 
                          type="range" min="0" max="50" step="1"
                          value={activeLayer.shadowBlur || 0} 
                          onChange={(e) => updateLayer(activeLayer.id, { shadowBlur: Number(e.target.value) })}
                          style={{ flex: 1, accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                        />
                        <input 
                          type="number"
                          value={activeLayer.shadowBlur || 0} 
                          onChange={(e) => updateLayer(activeLayer.id, { shadowBlur: Number(e.target.value) })}
                          style={{ width: '50px', textAlign: 'center' }}
                        />
                        <input 
                          type="color" 
                          value={activeLayer.shadowColor || '#000000'} 
                          onChange={(e) => updateLayer(activeLayer.id, { shadowColor: e.target.value })}
                          style={{ flex: 1, padding: '0', height: '36px', cursor: 'pointer' }}
                        />
                      </div>
                      <button 
                        className="btn btn-secondary" 
                        style={{ marginTop: '8px' }}
                        onClick={() => updateLayer(activeLayer.id, { shadowOffsetX: 0, shadowOffsetY: 0, shadowBlur: 0, shadowColor: 'transparent' })}
                      >Remove Shadow</button>
                    </div>
                  </div>
                </>
              ) : activeTextEffect === 'outline' ? (
                <>
                  <button className="btn" style={{ marginBottom: '16px', background: 'var(--bg-color)', border: '1px solid var(--border-color)', width: 'fit-content', padding: '6px 12px' }} onClick={() => setActiveTextEffect('menu')}>
                    ‹ Back
                  </button>
                  <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Outline</h3>
                  <div className="input-group">
                    <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                      <div style={{ display: 'flex', flex: 1, gap: '8px', alignItems: 'center' }}>
                        <input 
                          type="range" min="0" max="20" step="1"
                          value={activeLayer.outlineWidth || 0} 
                          onChange={(e) => updateLayer(activeLayer.id, { outlineWidth: Number(e.target.value) })}
                          style={{ flex: 1, accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                        />
                        <input 
                          type="number" placeholder="Width"
                          value={activeLayer.outlineWidth || 0} 
                          onChange={(e) => updateLayer(activeLayer.id, { outlineWidth: Number(e.target.value) })}
                          style={{ width: '50px', textAlign: 'center' }}
                        />
                      </div>
                      <input 
                        type="color" 
                        value={activeLayer.outlineColor || '#000000'} 
                        onChange={(e) => updateLayer(activeLayer.id, { outlineColor: e.target.value })}
                        style={{ flex: 1, padding: '0', height: '36px', cursor: 'pointer' }}
                      />
                    </div>
                  </div>
                </>
              ) : activeTextEffect === 'background' ? (
                <>
                  <button className="btn" style={{ marginBottom: '16px', background: 'var(--bg-color)', border: '1px solid var(--border-color)', width: 'fit-content', padding: '6px 12px' }} onClick={() => setActiveTextEffect('menu')}>
                    ‹ Back
                  </button>
                  <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Background Highlight</h3>
                  <div className="input-group">
                    <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                      <input 
                        type="color" 
                        value={activeLayer.textBackgroundColor || '#FFFFFF'} 
                        onChange={(e) => updateLayer(activeLayer.id, { textBackgroundColor: e.target.value })}
                        style={{ flex: 1, padding: '0', height: '36px', cursor: 'pointer' }}
                      />
                      <button 
                        className="btn btn-secondary" 
                        style={{ padding: '6px 12px', fontSize: '12px' }}
                        onClick={() => updateLayer(activeLayer.id, { textBackgroundColor: undefined })}
                      >Clear</button>
                    </div>
                  </div>
                </>
              ) : null}

            </div>
          )}

          {/* Case 3: Image Frame Active */}
          {activeLayer && activeLayer.type === 'image_frame' && (
            <div>
              <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Edit Frame</h3>
              
              {/* Only show shape option and border settings for custom frames */}
              {(!activeLayer.frameStyle || activeLayer.frameStyle === 'custom') && (
                <div className="input-group">
                  <label>Frame Shape</label>
                  <select 
                    value={activeLayer.shape || 'circle'} 
                    onChange={(e) => updateLayer(activeLayer.id, { shape: e.target.value })}
                  >
                    <option value="circle">Circle</option>
                    <option value="square">Square</option>
                    <option value="rounded-rectangle">Rounded Rectangle</option>
                    <option value="oval">Oval</option>
                    <option value="arch">Arch</option>
                  </select>
                </div>
              )}

              <div className="input-group">
                <label>Upload Photo</label>
                <button 
                  className="btn" 
                  style={{ width: '100%', border: '1px solid var(--border-color)', background: 'var(--bg-color)', gap: '8px' }}
                  onClick={() => {
                    const fileInput = document.createElement('input');
                    fileInput.type = 'file';
                    fileInput.accept = 'image/*';
                    fileInput.onchange = async (event: Event) => {
                      const target = event.target as HTMLInputElement;
                      if (target.files && target.files[0]) {
                        try {
                          const file = target.files[0];
                          const localUrl = URL.createObjectURL(file);
                          updateLayer(activeLayer.id, { src: localUrl });
                          
                          const serverUrl = await uploadFile(file);
                          updateLayer(activeLayer.id, { src: serverUrl });
                        } catch (err) {
                          console.error(err);
                          alert('Failed to upload photo to frame.');
                        }
                      }
                    };
                    fileInput.click();
                  }}
                >
                  <FileImage size={16} /> Upload New Photo
                </button>
              </div>

              {activeLayer.src && (
                <>
                  <div style={{ height: '1px', background: 'var(--border-color)', margin: '16px 0' }} />
                  <h4 style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '12px', textTransform: 'uppercase', letterSpacing: '0.5px', fontWeight: 'bold' }}>Image Position</h4>
                  
                  {/* Zoom Slider */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                      <span>Zoom</span>
                      <span>{Math.round((activeLayer.imageScale || 1) * 100)}%</span>
                    </div>
                    <input 
                      type="range" min="1" max="3" step="0.05"
                      value={activeLayer.imageScale || 1} 
                      onChange={(e) => updateLayer(activeLayer.id, { imageScale: parseFloat(e.target.value) })}
                      style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                    />
                  </div>

                  {/* Horizontal / Vertical Pan */}
                  <div style={{ display: 'flex', gap: '16px', marginBottom: '16px' }}>
                    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: 'var(--text-secondary)' }}>
                        <span>Horizontal</span>
                      </div>
                      <input 
                        type="range" min="-150" max="150" step="1"
                        value={activeLayer.imageOffsetX || 0} 
                        onChange={(e) => updateLayer(activeLayer.id, { imageOffsetX: parseInt(e.target.value) })}
                        style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                      />
                    </div>
                    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: 'var(--text-secondary)' }}>
                        <span>Vertical</span>
                      </div>
                      <input 
                        type="range" min="-150" max="150" step="1"
                        value={activeLayer.imageOffsetY || 0} 
                        onChange={(e) => updateLayer(activeLayer.id, { imageOffsetY: parseInt(e.target.value) })}
                        style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                      />
                    </div>
                  </div>
                  
                  <button 
                    className="btn btn-secondary" 
                    onClick={() => updateLayer(activeLayer.id, { imageScale: 1, imageOffsetX: 0, imageOffsetY: 0 })}
                    style={{ width: '100%', fontSize: '11px', padding: '6px' }}
                  >
                    Reset Position
                  </button>
                </>
              )}

              {/* Opacity Slider */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px', marginTop: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                  <span>Opacity</span>
                  <span>{Math.round((activeLayer.opacity !== undefined ? activeLayer.opacity : 1) * 100)}%</span>
                </div>
                <input 
                  type="range" min="0" max="1" step="0.05"
                  value={activeLayer.opacity !== undefined ? activeLayer.opacity : 1} 
                  onChange={(e) => updateLayer(activeLayer.id, { opacity: parseFloat(e.target.value) })}
                  style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                />
              </div>

              {/* Only show border settings for custom frames */}
              {(!activeLayer.frameStyle || activeLayer.frameStyle === 'custom') && (
                <>
                  {/* Border Width Slider */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                      <span>Border Width</span>
                      <span>{activeLayer.borderWidth || 0}px</span>
                    </div>
                    <input 
                      type="range" min="0" max="20" step="1"
                      value={activeLayer.borderWidth || 0} 
                      onChange={(e) => updateLayer(activeLayer.id, { borderWidth: parseInt(e.target.value) })}
                      style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                    />
                  </div>

                  {(activeLayer.borderWidth || 0) > 0 && (
                    <div className="input-group">
                      <label>Border Color</label>
                      <input 
                        type="color" 
                        value={activeLayer.borderColor || '#000000'} 
                        onChange={(e) => updateLayer(activeLayer.id, { borderColor: e.target.value })}
                        style={{ padding: '0', height: '40px', cursor: 'pointer' }}
                      />
                    </div>
                  )}
                </>
              )}
            </div>
          )}

          {/* Case 4: Shape Layer Active */}
          {activeLayer && activeLayer.type === 'shape' && (
            <div>
              <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Edit Shape</h3>
              
              {/* Tab Headers for Shape Fill */}
              <div style={{ display: 'flex', borderBottom: '1px solid var(--border-color)', marginBottom: '18px', gap: '5px' }}>
                <button 
                  type="button"
                  onClick={() => {
                    setShapeFillType('solid');
                    updateLayer(activeLayer.id, { color: shapeSolidColor });
                  }}
                  style={{
                    flex: 1, padding: '8px 0', border: 'none', background: 'none', fontSize: '12px', fontWeight: 'bold',
                    color: shapeFillType === 'solid' ? 'var(--accent-color)' : 'var(--text-secondary)',
                    borderBottom: shapeFillType === 'solid' ? '2px solid var(--accent-color)' : 'none',
                    cursor: 'pointer'
                  }}
                >Solid</button>
                <button 
                  type="button"
                  onClick={() => {
                    setShapeFillType('gradient');
                    const gradientStr = `linear-gradient(${shapeAngle}deg, ${shapeColor1}, ${shapeColor2})`;
                    updateLayer(activeLayer.id, { color: gradientStr });
                  }}
                  style={{
                    flex: 1, padding: '8px 0', border: 'none', background: 'none', fontSize: '12px', fontWeight: 'bold',
                    color: shapeFillType === 'gradient' ? 'var(--accent-color)' : 'var(--text-secondary)',
                    borderBottom: shapeFillType === 'gradient' ? '2px solid var(--accent-color)' : 'none',
                    cursor: 'pointer'
                  }}
                >Gradient</button>
              </div>

              {/* Tab Body: Solid Color */}
              {shapeFillType === 'solid' && (
                <div className="input-group">
                  <label>Fill Color</label>
                  <input 
                    type="color" 
                    value={shapeSolidColor} 
                    onChange={(e) => handleShapeSolidColorChange(e.target.value)}
                    style={{ padding: '0', height: '40px', cursor: 'pointer' }}
                  />
                </div>
              )}

              {/* Tab Body: Gradient */}
              {shapeFillType === 'gradient' && (
                <div>
                  <div className="input-group" style={{ marginBottom: '15px' }}>
                    <label>Gradient Style</label>
                    <select 
                      value={shapeGradientType}
                      onChange={(e) => handleShapeGradientChange(shapeColor1, shapeColor2, shapeAngle, e.target.value as 'two-color' | 'transparent')}
                    >
                      <option value="two-color">Two Colors</option>
                      <option value="transparent">Fade to Transparent</option>
                    </select>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: shapeGradientType === 'transparent' ? '1fr' : '1fr 1fr', gap: '10px', marginBottom: '15px' }}>
                    <div className="input-group" style={{ margin: 0 }}>
                      <label>{shapeGradientType === 'transparent' ? 'Color' : 'Color 1'}</label>
                      <input 
                        type="color" 
                        value={shapeColor1} 
                        onChange={(e) => handleShapeGradientChange(e.target.value, shapeColor2, shapeAngle)}
                        style={{ padding: '0', height: '40px', cursor: 'pointer' }}
                      />
                    </div>
                    {shapeGradientType === 'two-color' && (
                      <div className="input-group" style={{ margin: 0 }}>
                        <label>Color 2</label>
                        <input 
                          type="color" 
                          value={shapeColor2} 
                          onChange={(e) => handleShapeGradientChange(shapeColor1, e.target.value, shapeAngle)}
                          style={{ padding: '0', height: '40px', cursor: 'pointer' }}
                        />
                      </div>
                    )}
                  </div>

                  {/* Angle Slider */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '20px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                      <span>Angle</span>
                      <span>{shapeAngle}°</span>
                    </div>
                    <input 
                      type="range" min="0" max="360" step="5"
                      value={shapeAngle} 
                      onChange={(e) => handleShapeGradientChange(shapeColor1, shapeColor2, parseInt(e.target.value))}
                      style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                    />
                  </div>

                  {/* Preset Themes */}
                  <label style={{ display: 'block', fontSize: '11px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Presets</label>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', marginBottom: '15px' }}>
                    <button 
                      type="button"
                      onClick={() => handleShapeGradientChange('#1E252B', '#C5A880', 135)}
                      className="btn"
                      style={{ padding: '6px', fontSize: '11px', background: 'linear-gradient(135deg, #1E252B 30%, #C5A880 100%)', color: 'white', border: '1px solid var(--border-color)', textShadow: '0 1px 2px rgba(0,0,0,0.5)' }}
                    >Dawn Gold</button>
                    <button 
                      type="button"
                      onClick={() => handleShapeGradientChange('#4F5D75', '#2D3142', 135)}
                      className="btn"
                      style={{ padding: '6px', fontSize: '11px', background: 'linear-gradient(135deg, #4F5D75 30%, #2D3142 100%)', color: 'white', border: '1px solid var(--border-color)', textShadow: '0 1px 2px rgba(0,0,0,0.5)' }}
                    >Serene Slate</button>
                    <button 
                      type="button"
                      onClick={() => handleShapeGradientChange('#E2E8F0', '#CBD5E1', 135)}
                      className="btn"
                      style={{ padding: '6px', fontSize: '11px', background: 'linear-gradient(135deg, #E2E8F0 30%, #CBD5E1 100%)', color: 'var(--text-primary)', border: '1px solid var(--border-color)' }}
                    >Eternal Peace</button>
                    <button 
                      type="button"
                      onClick={() => handleShapeGradientChange('#3A2E39', '#1E1B1E', 135)}
                      className="btn"
                      style={{ padding: '6px', fontSize: '11px', background: 'linear-gradient(135deg, #3A2E39 30%, #1E1B1E 100%)', color: 'white', border: '1px solid var(--border-color)', textShadow: '0 1px 2px rgba(0,0,0,0.5)' }}
                    >Sunset Rose</button>
                  </div>
                </div>
              )}

              {/* Opacity Slider */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                  <span>Opacity</span>
                  <span>{Math.round((activeLayer.opacity !== undefined ? activeLayer.opacity : 1) * 100)}%</span>
                </div>
                <input 
                  type="range" min="0" max="1" step="0.05"
                  value={activeLayer.opacity !== undefined ? activeLayer.opacity : 1} 
                  onChange={(e) => updateLayer(activeLayer.id, { opacity: parseFloat(e.target.value) })}
                  style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                />
              </div>

              {/* Border Width Slider */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                  <span>Border Width</span>
                  <span>{activeLayer.borderWidth || 0}px</span>
                </div>
                <input 
                  type="range" min="0" max="20" step="1"
                  value={activeLayer.borderWidth || 0} 
                  onChange={(e) => updateLayer(activeLayer.id, { borderWidth: parseInt(e.target.value) })}
                  style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                />
              </div>

              {(activeLayer.borderWidth || 0) > 0 && (
                <div className="input-group">
                  <label>Border Color</label>
                  <input 
                    type="color" 
                    value={activeLayer.borderColor || '#000000'} 
                    onChange={(e) => updateLayer(activeLayer.id, { borderColor: e.target.value })}
                    style={{ padding: '0', height: '40px', cursor: 'pointer' }}
                  />
                </div>
              )}

              {/* Corner Roundness Slider (only for Square or Rounded Rectangle shapes) */}
              {(activeLayer.shape === 'square' || activeLayer.shape === 'rounded-rectangle') && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                    <span>Corner Roundness</span>
                    <span>{activeLayer.borderRadius !== undefined ? activeLayer.borderRadius : (activeLayer.shape === 'rounded-rectangle' ? 20 : 0)}px</span>
                  </div>
                  <input 
                    type="range" min="0" max="100" step="1"
                    value={activeLayer.borderRadius !== undefined ? activeLayer.borderRadius : (activeLayer.shape === 'rounded-rectangle' ? 20 : 0)} 
                    onChange={(e) => updateLayer(activeLayer.id, { borderRadius: parseInt(e.target.value) })}
                    style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                  />
                </div>
              )}
            </div>
          )}

          {/* Case 5: Image Overlay Active */}
          {activeLayer && activeLayer.type === 'image' && (
            <div>
              <h3 style={{ fontSize: '14px', margin: '0 0 16px 0', textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Edit Photo</h3>
              
              {/* Opacity Slider */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                  <span>Opacity</span>
                  <span>{Math.round((activeLayer.opacity !== undefined ? activeLayer.opacity : 1) * 100)}%</span>
                </div>
                <input 
                  type="range" min="0" max="1" step="0.05"
                  value={activeLayer.opacity !== undefined ? activeLayer.opacity : 1} 
                  onChange={(e) => updateLayer(activeLayer.id, { opacity: parseFloat(e.target.value) })}
                  style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                />
              </div>

              {/* Border Width Slider */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>
                  <span>Border Width</span>
                  <span>{activeLayer.borderWidth || 0}px</span>
                </div>
                <input 
                  type="range" min="0" max="20" step="1"
                  value={activeLayer.borderWidth || 0} 
                  onChange={(e) => updateLayer(activeLayer.id, { borderWidth: parseInt(e.target.value) })}
                  style={{ width: '100%', accentColor: 'var(--accent-color)', cursor: 'pointer' }}
                />
              </div>

              {(activeLayer.borderWidth || 0) > 0 && (
                <div className="input-group">
                  <label>Border Color</label>
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

      {/* Right-click Context Menu */}
      {contextMenu.visible && (
        <div 
          style={{
            position: 'fixed',
            top: contextMenu.y,
            left: contextMenu.x,
            backgroundColor: 'white',
            border: '1px solid var(--border-color)',
            borderRadius: 'var(--radius-md)',
            boxShadow: 'var(--shadow-lg)',
            padding: '4px 0',
            zIndex: 99999,
            minWidth: '140px',
            display: 'flex',
            flexDirection: 'column'
          }}
          onClick={(e) => e.stopPropagation()}
        >
          {selectedLayerIds.length > 1 && (
            <button 
              type="button" 
              onClick={() => { groupSelectedLayers(); setContextMenu(prev => ({ ...prev, visible: false })); }}
              style={{
                background: 'none', border: 'none', textAlign: 'left', padding: '8px 16px', fontSize: '13px', fontWeight: '600', color: 'var(--text-primary)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px'
              }}
              onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'var(--surface-color)'}
              onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 3v18"/><path d="M15 3v18"/><path d="M3 9h18"/><path d="M3 15h18"/></svg>
              Group
            </button>
          )}

          {selectedLayerIds.length === 1 && layers.find(l => l.id === selectedLayerIds[0])?.type === 'group' && (
            <button 
              type="button" 
              onClick={() => { ungroupSelectedLayers(); setContextMenu(prev => ({ ...prev, visible: false })); }}
              style={{
                background: 'none', border: 'none', textAlign: 'left', padding: '8px 16px', fontSize: '13px', fontWeight: '600', color: 'var(--text-primary)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px'
              }}
              onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'var(--surface-color)'}
              onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="8" height="8" rx="1"/><rect x="13" y="13" width="8" height="8" rx="1"/><path d="M13 3h8v8"/><path d="M3 13v8h8"/></svg>
              Ungroup
            </button>
          )}

          {contextMenu.layerId && (
            <>
              <button 
                type="button" 
                onClick={() => {
                  const duplicated: Layer[] = [];
                  layers.forEach(layer => {
                    if (selectedLayerIds.includes(layer.id)) {
                      duplicated.push({
                        ...layer,
                        id: `${layer.id}-copy-${Date.now()}`,
                        x: layer.x + 40,
                        y: layer.y + 40,
                        children: layer.children ? layer.children.map(c => ({ ...c, id: `${c.id}-copy-${Date.now()}` })) : undefined
                      });
                    }
                  });
                  setLayers([...layers, ...duplicated]);
                  setSelectedLayerIds(duplicated.map(l => l.id));
                  setActiveLayerId(duplicated[0]?.id || null);
                  setContextMenu(prev => ({ ...prev, visible: false }));
                }}
                style={{
                  background: 'none', border: 'none', textAlign: 'left', padding: '8px 16px', fontSize: '13px', fontWeight: '600', color: 'var(--text-primary)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px'
                }}
                onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'var(--surface-color)'}
                onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                Duplicate
              </button>

              <button 
                type="button" 
                onClick={() => {
                  setLayers(layers.filter(l => !selectedLayerIds.includes(l.id)));
                  selectLayer(null);
                  setContextMenu(prev => ({ ...prev, visible: false }));
                }}
                style={{
                  background: 'none', border: 'none', textAlign: 'left', padding: '8px 16px', fontSize: '13px', fontWeight: '600', color: '#EF4444', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px'
                }}
                onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'var(--surface-color)'}
                onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
              >
                <Trash2 size={14} /> Delete
              </button>
            </>
          )}

          {!contextMenu.layerId && (
            <span style={{ fontSize: '11px', color: 'var(--text-muted)', padding: '6px 16px', fontWeight: '500' }}>
              Canvas Menu
            </span>
          )}
        </div>
      )}

      {/* Selection Marquee Rect */}
      {selectionBox && (
        <div 
          style={{
            position: 'fixed',
            left: Math.min(selectionBox.startX, selectionBox.currentX),
            top: Math.min(selectionBox.startY, selectionBox.currentY),
            width: Math.abs(selectionBox.startX - selectionBox.currentX),
            height: Math.abs(selectionBox.startY - selectionBox.currentY),
            border: '1.5px solid var(--accent-color)',
            backgroundColor: 'rgba(197, 168, 128, 0.12)',
            zIndex: 999999,
            pointerEvents: 'none',
            borderRadius: '1px'
          }}
        />
      )}
        </div>
      </aside>
    </div>
  );
}
