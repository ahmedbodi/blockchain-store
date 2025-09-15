import {useMutation, useQuery, useQueryClient} from '@tanstack/react-query'
import {toast} from 'sonner'
import {api} from '@/lib/api'

type CustomConfigResponse = {lines: string}

// Returns `{ lines }` where `lines` is the text after the banner in bitcoin.conf.
export function useCustomConfig() {
	return useQuery({
		queryKey: ['config', 'custom-options'],
		queryFn: () => api<CustomConfigResponse>('/config/custom-options'),
		staleTime: 30_000,
	})
}

// Save the custom config to the backend
export function useSaveCustomConfig() {
	const qc = useQueryClient()

	return useMutation({
		mutationFn: (lines: string) => api('/config/custom-options', {method: 'PATCH', body: {lines}}),

		onSuccess: () => {
			// refresh textarea
			qc.invalidateQueries({queryKey: ['config', 'custom-options']})

			// clear crash UI
			qc.setQueryData(['catcoind', 'exit'], null)

			// clear bitcoin crash toast if it is still showing
			toast.dismiss('catcoind-exit')

			// Purge and kickoff background refetches for rpc data
			qc.removeQueries({queryKey: ['rpc']})
			qc.invalidateQueries({queryKey: ['rpc']})
		},
	})
}
