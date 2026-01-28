import React from 'react';
import { VectorPath } from '../types';
import { formatPathD } from '../utils/vectorUtils';
import { X, Copy, Check } from 'lucide-react';

interface ExportModalProps {
    isOpen: boolean;
    onClose: () => void;
    paths: VectorPath[];
}

const ExportModal: React.FC<ExportModalProps> = ({ isOpen, onClose, paths }) => {
    const [copied, setCopied] = React.useState(false);

    if (!isOpen) return null;

    const generateSvgCode = () => {
        const pathTags = paths.map(p => 
            `  <path id="${p.id}" d="${formatPathD(p.nodes, p.closed)}" fill="${p.fill}" stroke="${p.stroke}" stroke-width="${p.strokeWidth}" />`
        ).join('\n');

        return `<svg width="800" height="600" viewBox="0 0 800 600" xmlns="http://www.w3.org/2000/svg">\n${pathTags}\n</svg>`;
    };

    const code = generateSvgCode();

    const handleCopy = () => {
        navigator.clipboard.writeText(code);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    return (
         <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
            <div className="bg-[#2b2b2b] border border-[#3a3a3a] rounded-xl shadow-2xl w-full max-w-2xl flex flex-col max-h-[80vh]">
                <div className="p-4 border-b border-[#3a3a3a] flex justify-between items-center bg-[#252525]">
                    <h2 className="font-semibold text-white">Export SVG</h2>
                    <button onClick={onClose} className="text-[#888] hover:text-white">
                        <X size={18} />
                    </button>
                </div>
                
                <div className="p-0 flex-1 relative overflow-hidden">
                    <pre className="w-full h-full bg-[#1a1a1a] p-4 text-xs text-green-400 font-mono overflow-auto selection:bg-green-900">
                        {code}
                    </pre>
                    <button 
                        onClick={handleCopy}
                        className="absolute top-4 right-4 bg-[#333] hover:bg-[#444] text-white p-2 rounded border border-[#555] flex items-center space-x-2 shadow-lg"
                    >
                        {copied ? <Check size={14} className="text-green-400"/> : <Copy size={14} />}
                        <span className="text-xs">{copied ? 'Copied' : 'Copy'}</span>
                    </button>
                </div>
            </div>
         </div>
    );
}

export default ExportModal;
